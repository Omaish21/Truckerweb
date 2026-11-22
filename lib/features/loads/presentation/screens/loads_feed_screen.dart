import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ai/trucklink_ai_service.dart';
import '../../../../core/constants/load_statuses.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/providers/app_scope.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/launcher/app_launcher.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/ai_copilot_sheet.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/truck_icon.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/bid_model.dart';
import '../../domain/load_model.dart';

class LoadsFeedScreen extends StatefulWidget {
  final String? initialCity;
  final String? initialVehicle;

  const LoadsFeedScreen({
    super.key,
    this.initialCity,
    this.initialVehicle,
  });

  @override
  State<LoadsFeedScreen> createState() => _LoadsFeedScreenState();
}

class _LoadsFeedScreenState extends State<LoadsFeedScreen> {
  String? _selectedVehicleFilter;
  String? _selectedCityFilter;
  final Map<String, String> _translatedNotes = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _selectedCityFilter = widget.initialCity;
    }
    if (widget.initialVehicle != null && widget.initialVehicle!.isNotEmpty) {
      _selectedVehicleFilter = widget.initialVehicle;
    }
  }

  void _syncUrl() {
    if (!mounted) return;
    final params = <String, String>{};
    if (_selectedCityFilter != null && _selectedCityFilter != 'All') {
      params['city'] = _selectedCityFilter!;
    }
    if (_selectedVehicleFilter != null && _selectedVehicleFilter != 'all') {
      params['vehicle'] = _selectedVehicleFilter!;
    }
    final uri = Uri(
      path: '/loads-feed',
      queryParameters: params.isEmpty ? null : params,
    );
    GoRouter.of(context).replace(uri.toString());
  }

  final List<String> _majorHubs = const [
    'All',
    'Karachi',
    'Lahore',
    'Faisalabad',
    'Multan',
    'Rawalpindi',
    'Peshawar',
  ];

  Future<void> _launchPhoneCall(String phone) async {
    await AppLauncher.makeCall(phone);
  }

  Future<void> _launchWhatsApp(String phone, LoadModel load, bool isUrdu) async {
    final message = isUrdu
        ? 'السلام علیکم، میں TruckLink PK (ٹرک لنک پی کے) پر آپ کا لوڈ (${load.originCity} تا ${load.destinationCity} - ${load.weightTons} ٹن) دیکھ رہا ہوں۔ کیا یہ دستیاب ہے؟'
        : 'Salam, I saw your load from ${load.originCity} to ${load.destinationCity} (${load.weightTons} tons) on TruckLink PK. Is it available?';
    await AppLauncher.openWhatsApp(phone: phone, message: message);
  }

  void _showBidDialog(BuildContext context, LoadModel load) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final rateCtrl = TextEditingController(text: load.offeredRatePkr.toInt().toString());
    final hoursCtrl = TextEditingController(text: '24');
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUrdu ? 'بولی لگائیں (Counter-Offer)' : 'Submit Load Bid',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${load.originCity} ➔ ${load.destinationCity} (${load.weightTons} Tons)',
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? '💡 منافع کا تخمینہ: موجودہ ڈیزل (285 روپے/لیٹر) اور ٹول ٹیکس کو مدنظر رکھ کر بولی درج کریں۔'
                            : '💡 Margin Advisor: Factor in current diesel (~PKR 285/L) and highway tolls when proposing your bid.',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                cursorColor: AppColors.primary,
                cursorWidth: 2.2,
                showCursor: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'آپ کی پیشکش (روپے)' : 'Proposed Rate (PKR)',
                  prefixIcon: const Icon(Icons.payments, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                cursorColor: AppColors.primary,
                cursorWidth: 2.2,
                showCursor: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'متوقع وقت (گھنٹے)' : 'Estimated Delivery (Hours)',
                  prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                cursorColor: AppColors.primary,
                cursorWidth: 2.2,
                showCursor: true,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'ڈرائیور نوٹس / شرائط' : 'Driver Notes / Terms',
                  prefixIcon: const Icon(Icons.edit_note, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final authUser = context.auth.userProfile;
                  final newBid = BidModel(
                    id: '',
                    loadId: load.id,
                    driverId: authUser?.id ?? '',
                    driverName: (authUser?.fullName.isNotEmpty == true) ? authUser!.fullName : (isUrdu ? 'ڈرائیور' : 'Driver'),
                    driverPhone: authUser?.phone ?? '',
                    driverRating: authUser?.rating ?? 0.0,
                    isVerifiedDriver: authUser?.cnicVerified ?? false,
                    proposedRatePkr: double.tryParse(rateCtrl.text.trim()) ?? load.offeredRatePkr,
                    estimatedHours: int.tryParse(hoursCtrl.text.trim()) ?? 24,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await FirebaseService.instance.submitBid(load.id, newBid);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(isUrdu ? 'آپ کی بولی کامیابی سے بھیج دی گئی' : 'Bid submitted successfully!'),
                      ),
                    );
                  }
                },
                child: Text(
                  isUrdu ? 'بولی جمع کرائیں' : 'Submit Counter-Offer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBidsViewer(BuildContext context, LoadModel load) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StreamBuilder<List<BidModel>>(
          stream: FirebaseService.bidsStream(load.id),
          builder: (context, snapshot) {
            final bids = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUrdu ? 'وصول شدہ بولیاں (${bids.length})' : 'Incoming Bids (${bids.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (bids.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          isUrdu ? 'ابھی تک کوئی بولی موصول نہیں ہوئی' : 'No bids submitted yet.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: bids.length,
                        itemBuilder: (context, index) {
                          final bid = bids[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            bid.driverName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(width: 8),
                                          VerifiedBadge(isVerified: bid.isVerifiedDriver),
                                        ],
                                      ),
                                      Text(
                                        AppFormatters.formatPkr(bid.proposedRatePkr),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${isUrdu ? 'ڈیلیوری ٹائم' : 'ETA'}: ${bid.estimatedHours} ${isUrdu ? 'گھنٹے' : 'hours'} • ⭐ ${bid.driverRating}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                  if (bid.notes != null) ...[
                                    const SizedBox(height: 6),
                                    Text('"${bid.notes}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 10),
                                  if (bid.status == 'accepted')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isUrdu ? 'منظور شدہ بولی' : 'Accepted Bid',
                                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        await FirebaseService.instance.acceptBid(
                                          loadId: load.id,
                                          bidId: bid.id,
                                          driverId: bid.driverId,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: AppColors.success,
                                              content: Text(
                                                isUrdu ? 'ڈرائیور کی بولی منظور کر لی گئی!' : 'Driver bid accepted!',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(isUrdu ? 'بولی منظور کریں' : 'Accept Bid'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final authUser = context.auth.userProfile;

    return StreamBuilder<List<LoadModel>>(
      stream: FirebaseService.loadsStream,
      initialData: const <LoadModel>[],
      builder: (context, snapshot) {
        var loadsList = snapshot.data ?? const <LoadModel>[];

        // Apply vehicle type filtering
        if (_selectedVehicleFilter != null && _selectedVehicleFilter != 'all') {
          loadsList = loadsList.where((l) => l.vehicleTypeRequired == _selectedVehicleFilter).toList();
        }

        // Apply city hub filtering
        if (_selectedCityFilter != null && _selectedCityFilter != 'All') {
          loadsList = loadsList.where((l) =>
              l.originCity.toLowerCase().contains(_selectedCityFilter!.toLowerCase()) ||
              l.destinationCity.toLowerCase().contains(_selectedCityFilter!.toLowerCase())).toList();
        }

        return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28, borderRadius: 6),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.availableLoadsTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: isUrdu ? 'استاد جی اے آئی کو پائلٹ' : 'TruckLink AI Co-Pilot',
            onPressed: () => AiCopilotSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isUrdu ? 'لوڈز فیڈ کا لنک شیئر کریں' : 'Share Feed Link',
            onPressed: () {
              final baseUri = Uri.base;
              final params = <String, String>{};
              if (_selectedCityFilter != null && _selectedCityFilter != 'All') {
                params['city'] = _selectedCityFilter!;
              }
              if (_selectedVehicleFilter != null && _selectedVehicleFilter != 'all') {
                params['vehicle'] = _selectedVehicleFilter!;
              }
              final queryStr = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
              final shareUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}/loads-feed$queryStr';
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    isUrdu
                        ? 'لوڈز فیڈ کا لنک کاپی کر لیا گیا ہے: $shareUrl'
                        : 'Loads feed link copied to clipboard: $shareUrl',
                  ),
                ),
              );
            },
          ),
          if (context.auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: l10n.adminVerification,
              onPressed: () => context.go('/admin/verification'),
            ),
          const NotificationBellButton(),
          const Center(
            child: LanguageToggleButton(compact: true),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.postNewLoad,
            onPressed: () => context.push('/post-load'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(l10n.postNewLoad, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/post-load'),
      ),
      body: Column(
        children: [
          // Filter Chips 1: Vehicle Types
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(isUrdu ? 'تمام گاڑیاں' : 'All Trucks'),
                    selected: _selectedVehicleFilter == null || _selectedVehicleFilter == 'all',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: (_selectedVehicleFilter == null || _selectedVehicleFilter == 'all') ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedVehicleFilter = 'all');
                        _syncUrl();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...VehicleType.all.map((vt) {
                    final isSel = _selectedVehicleFilter == vt.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: TruckIcon(vehicleType: vt.id, size: 18),
                        label: Text(isUrdu ? vt.nameUr : vt.nameEn),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedVehicleFilter = val ? vt.id : null);
                          _syncUrl();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Filter Chips 2: Pakistani Hubs
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _majorHubs.map((hub) {
                  final isSel = (_selectedCityFilter == null && hub == 'All') || _selectedCityFilter == hub;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(hub),
                      selected: isSel,
                      selectedColor: AppColors.accent.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.primary,
                      onSelected: (val) {
                        setState(() => _selectedCityFilter = hub == 'All' ? null : hub);
                        _syncUrl();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loads List
          Expanded(
            child: loadsList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            isUrdu ? 'کوئی لوڈ دستیاب نہیں ہے' : 'No Loads Posted Yet',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUrdu
                                ? 'ابھی تک کوئی نیا مال پوسٹ نہیں کیا گیا ہے۔ نیا لوڈ پوسٹ کرنے کے لیے نیچے بٹن دبائیں۔'
                                : 'There are currently no active freight loads matching this filter. Post a load to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.postNewLoad),
                            onPressed: () => context.push('/post-load'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: loadsList.length,
                    itemBuilder: (context, index) {
                      final load = loadsList[index];
                      final contactPhone = load.contactPhone ?? '';
                      final isMyLoad = authUser != null && authUser.id == load.ownerId;
                      final isAssignedToMe = authUser != null && authUser.id == load.assignedDriverId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TruckIcon(vehicleType: load.vehicleTypeRequired, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${load.originCity} ➔ ${load.destinationCity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${load.goodsType ?? l10n.goodsGeneral} • ${l10n.tonsUnit(load.weightTons.toInt().toString())}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        mouseCursor: SystemMouseCursors.click,
                                        onTap: () {
                                          final current = load.goodsType ?? l10n.goodsGeneral;
                                          final trans = TranslationService().translate(
                                            text: current,
                                            targetLanguageCode: isUrdu ? 'ur' : 'en',
                                          );
                                          setState(() => _translatedNotes[load.id] = trans);
                                        },
                                        child: Text(
                                          _translatedNotes[load.id] != null
                                              ? '(${_translatedNotes[load.id]})'
                                              : (isUrdu ? '🌐 ترجمہ' : '🌐 Translate'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final match = TruckLinkAiService.instance.matchDriverToLoad(
                                      driver: authUser,
                                      load: load,
                                    );
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 12, color: Colors.amberAccent),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${match.percentage}% AI Match',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: load.status == LoadStatus.open
                                        ? AppColors.success.withValues(alpha: 0.12)
                                        : AppColors.accent.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    LoadStatus.getLabel(load.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: load.status == LoadStatus.open ? AppColors.success : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // One-tap Call & WhatsApp Buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.phone, size: 16, color: AppColors.primary),
                              label: Text(isUrdu ? 'کال کریں' : 'Call Shipper'),
                              onPressed: () => _launchPhoneCall(contactPhone),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat, size: 16),
                              label: Text(isUrdu ? 'واٹس ایپ' : 'WhatsApp'),
                              onPressed: () => _launchWhatsApp(contactPhone, load, isUrdu),
                            ),
                            const Spacer(),
                            Text(
                              AppFormatters.formatPkr(load.offeredRatePkr),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Action Buttons: Bidding, Route Inspect, Status Lifecycle
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Bid button for drivers
                            OutlinedButton.icon(
                              icon: const Icon(Icons.gavel, size: 16),
                              label: Text(isUrdu ? 'بولی لگائیں' : 'Submit Bid'),
                              onPressed: () => _showBidDialog(context, load),
                            ),

                            // Map / Route Preview button
                            OutlinedButton.icon(
                              icon: const Icon(Icons.map_outlined, size: 16, color: AppColors.accentOrange),
                              label: Text(isUrdu ? 'گوگل روٹ' : 'Route Map'),
                              onPressed: () {
                                context.push(
                                  '/route-planner?origin=${Uri.encodeComponent(load.originCity)}&destination=${Uri.encodeComponent(load.destinationCity)}&vehicle=${Uri.encodeComponent(load.vehicleTypeRequired)}',
                                );
                              },
                            ),

                            // View Bids button
                            TextButton.icon(
                              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                              label: Text(
                                isUrdu
                                    ? 'بولیاں دیکھیں (${load.bidsCount})'
                                    : 'View Bids (${load.bidsCount})',
                              ),
                              onPressed: () => _showBidsViewer(context, load),
                            ),

                            // Share Load Card button
                            IconButton(
                              icon: const Icon(Icons.share, size: 18, color: AppColors.primary),
                              tooltip: isUrdu ? 'لوڈ شیئر کریں' : 'Share Load',
                              onPressed: () {
                                final baseUri = Uri.base;
                                final shareUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}/route-planner?origin=${Uri.encodeComponent(load.originCity)}&destination=${Uri.encodeComponent(load.destinationCity)}&vehicle=${Uri.encodeComponent(load.vehicleTypeRequired)}';
                                final loadDetails = '${load.originCity} ➔ ${load.destinationCity} (${load.weightTons}T, ${AppFormatters.formatPkr(load.offeredRatePkr)})\n$shareUrl';
                                Clipboard.setData(ClipboardData(text: loadDetails));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    content: Text(isUrdu ? 'لوڈ کا لنک کاپی کر لیا گیا ہے' : 'Load link copied!'),
                                    action: SnackBarAction(
                                      label: isUrdu ? 'واٹس ایپ' : 'WhatsApp',
                                      textColor: AppColors.accent,
                                      onPressed: () {
                                        final msg = isUrdu
                                            ? 'TruckLink PK (ٹرک لنک پی کے) پر یہ لوڈ دیکھیں:\n$loadDetails'
                                            : 'Check this load on TruckLink PK:\n$loadDetails';
                                        AppLauncher.openWhatsApp(phone: '', message: msg);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Route Inspector button
                            IconButton(
                              icon: const Icon(Icons.alt_route, color: AppColors.primary),
                              tooltip: l10n.inspectRoute,
                              onPressed: () => context.push(
                                '/route-planner?origin=${Uri.encodeComponent(load.originCity)}&destination=${Uri.encodeComponent(load.destinationCity)}&vehicle=${Uri.encodeComponent(load.vehicleTypeRequired)}',
                              ),
                            ),

                            // Trip Lifecycle progression for assigned driver
                            if (isAssignedToMe || isMyLoad) ...[
                              if (load.status == LoadStatus.assigned)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: Text(isUrdu ? 'سفر شروع کریں' : 'Start Trip'),
                                  onPressed: () async {
                                    await FirebaseService.instance.updateLoadStatus(load.id, LoadStatus.inTransit);
                                  },
                                )
                              else if (load.status == LoadStatus.inTransit)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: Text(isUrdu ? 'مال پہنچ گیا' : 'Mark Delivered'),
                                  onPressed: () async {
                                    await FirebaseService.instance.updateLoadStatus(load.id, LoadStatus.delivered);
                                  },
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
