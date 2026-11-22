import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';
import '../services/google_maps_service.dart';
import '../theme/colors.dart';

/// Interactive Geocoding & Logistics Location Picker Widget.
/// Zero external package dependency; pure Flutter and Google Geocoding API.
class LocationSearchBar extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<GeocodingLocation> onLocationSelected;
  final IconData leadingIcon;
  final bool showQuickHubs;

  const LocationSearchBar({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onLocationSelected,
    this.leadingIcon = Icons.location_on,
    this.showQuickHubs = true,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestionsOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideSuggestionsOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      _updateOverlay();
      return;
    }

    setState(() => _isLoading = true);
    final results = await GoogleMapsService.getPlaceSuggestions(query);

    // Merge with any matching offline logistics landmarks
    final landmarkMatches = GeocodingService.majorLogisticsLandmarks
        .where((l) =>
            l.nameEn.toLowerCase().contains(query.toLowerCase()) ||
            l.city.toLowerCase().contains(query.toLowerCase()))
        .map((l) => '${l.nameEn} (${l.city})')
        .toList();

    final merged = <String>{...landmarkMatches, ...results}.toList();

    if (mounted) {
      setState(() {
        _suggestions = merged.take(6).toList();
        _isLoading = false;
      });
      _updateOverlay();
    }
  }

  void _selectLocation(String address) async {
    _controller.text = address;
    _hideSuggestionsOverlay();
    _focusNode.unfocus();

    final resolved = await GeocodingService.instance.forwardGeocode(address);
    if (resolved != null && mounted) {
      widget.onLocationSelected(resolved);
    }
  }

  void _showSuggestionsOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Type to search cities, dry ports, or toll plazas...',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final item = _suggestions[index];
                            final isHub = item.contains('Dry Port') ||
                                item.contains('Port') ||
                                item.contains('Toll');

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isHub ? Icons.warehouse : Icons.location_on,
                                color: isHub ? AppColors.accentOrange : AppColors.primary,
                                size: 18,
                              ),
                              title: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isHub ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              trailing: isHub
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Verified Hub',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : null,
                              onTap: () => _selectLocation(item),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.leadingIcon, color: AppColors.primary, size: 20),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          if (widget.showQuickHubs) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip('Lahore (Badami Bagh)'),
                  _quickChip('Karachi Port'),
                  _quickChip('Faisalabad Dry Port'),
                  _quickChip('Port Qasim'),
                  _quickChip('Multan Sher Shah'),
                  _quickChip('Sialkot Sambrial'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickChip(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(name, style: const TextStyle(fontSize: 11)),
        avatar: const Icon(Icons.tag, size: 13, color: AppColors.primary),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: () => _selectLocation(name),
      ),
    );
  }
}
