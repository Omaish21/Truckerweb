import 'dart:async';
import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';
import '../services/google_maps_service.dart';
import '../theme/colors.dart';

/// Interactive Google Maps Places & Logistics Location Search Widget.
/// Supports real-time Google Places Autocomplete API + offline Pakistani hubs catalog.
class LocationSearchBar extends StatefulWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<GeocodingLocation>? onLocationSelected;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onChanged;
  final IconData leadingIcon;
  final Color? iconColor;
  final String? hintText;
  final bool showQuickHubs;
  final List<String>? quickHubs;

  const LocationSearchBar({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.validator,
    this.onLocationSelected,
    this.onSelected,
    this.onChanged,
    this.leadingIcon = Icons.location_on,
    this.iconColor,
    this.hintText,
    this.showQuickHubs = true,
    this.quickHubs,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  List<String> _suggestions = [];
  bool _isLoading = false;

  static const List<String> _defaultHubs = [
    'Lahore (Badami Bagh)',
    'Karachi Port (KPT)',
    'Port Qasim',
    'Faisalabad Dry Port',
    'Multan (Chowk Kumharan)',
    'Rawalpindi (Pirwadhai)',
    'Peshawar (Chamkani)',
    'Quetta Dry Port',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue ?? '');
    }
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
    _debounceTimer?.cancel();
    _hideSuggestionsOverlay();
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      _updateOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      _updateOverlay();

      // Query Google Maps Places API (JS or REST)
      final googleResults = await GoogleMapsService.getPlaceSuggestions(query);

      // Match against offline verified Pakistani logistics hubs
      final landmarkMatches = GeocodingService.majorLogisticsLandmarks
          .where((l) =>
              l.nameEn.toLowerCase().contains(query.toLowerCase()) ||
              l.city.toLowerCase().contains(query.toLowerCase()) ||
              l.nameUr.contains(query))
          .map((l) => '${l.nameEn} (${l.city})')
          .toList();

      final merged = <String>{...landmarkMatches, ...googleResults}.toList();

      if (mounted) {
        setState(() {
          _suggestions = merged.take(8).toList();
          _isLoading = false;
        });
        _updateOverlay();
      }
    });
  }

  void _selectLocation(String address) async {
    _effectiveController.text = address;
    _hideSuggestionsOverlay();
    _focusNode.unfocus();

    widget.onChanged?.call(address);
    widget.onSelected?.call(address);

    if (widget.onLocationSelected != null) {
      final resolved = await GeocodingService.instance.forwardGeocode(address);
      if (resolved != null && mounted) {
        widget.onLocationSelected!(resolved);
      }
    }
    setState(() {});
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null) return;
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
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            shadowColor: Colors.black26,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search Google Maps or select a quick logistics hub below...',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
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
                                item.contains('Toll') ||
                                item.contains('Adda') ||
                                item.contains('Terminal');

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isHub ? Icons.warehouse : Icons.location_on,
                                color: isHub ? AppColors.accentOrange : (widget.iconColor ?? AppColors.primary),
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
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        'Verified Hub',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
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
    final chips = widget.quickHubs ?? _defaultHubs;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _effectiveController,
            focusNode: _focusNode,
            validator: widget.validator,
            onChanged: (val) {
              widget.onChanged?.call(val);
              _onQueryChanged(val);
            },
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: Icon(
                widget.leadingIcon,
                color: widget.iconColor ?? AppColors.primary,
                size: 20,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _effectiveController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _effectiveController.clear();
                            widget.onChanged?.call('');
                            _onQueryChanged('');
                            setState(() {});
                          },
                        )
                      : const Icon(Icons.search, size: 20, color: Colors.grey),
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
                children: chips.map((hub) => _quickChip(hub)).toList(),
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
        avatar: Icon(
          Icons.tag,
          size: 13,
          color: widget.iconColor ?? AppColors.primary,
        ),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: () => _selectLocation(name),
      ),
    );
  }
}
