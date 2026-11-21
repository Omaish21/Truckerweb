import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/load_statuses.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/truck_icon.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/bid_model.dart';
import '../../domain/load_model.dart';

class LoadsFeedScreen extends ConsumerStatefulWidget {
  const LoadsFeedScreen({super.key});

  @override
  ConsumerState<LoadsFeedScreen> createState() => _LoadsFeedScreenState();
}

class _LoadsFeedScreenState extends ConsumerState<LoadsFeedScreen> {
  String? _selectedVehicleFilter;
  String? _selectedCityFilter;
  final Map<String, String> _translatedNotes = {};

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
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Launch phone error: $e');
    }
  }

  Future<void> _launchWhatsApp(String phone, LoadModel load, bool isUrdu) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    }
    final message = isUrdu
        ? 'السلام علیکم، میں TruckLink PK پر آپ کا لوڈ (${load.originCity} تا ${load.destinationCity} - ${load.weightTons} ٹن) دیکھ رہا ہوں۔ کیا یہ دستیاب ہے؟'
        : 'Salam, I saw your load from ${load.originCity} to ${load.destinationCity} (${load.weightTons} tons) on TruckLink PK. Is it available?';
    final url = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Launch WhatsApp error: $e');
    }
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
              const SizedBox(height: 16),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'آپ کی پیشکش (روپے)' : 'Proposed Rate (PKR)',
                  prefixIcon: const Icon(Icons.payments, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'متوقع وقت (گھنٹے)' : 'Estimated Delivery (Hours)',
                  prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
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
                  final authUser = ref.read(authProvider).userProfile;
                  final newBid = BidModel(
                    id: '',
                    loadId: load.id,
                    driverId: authUser?.id ?? 'driver-1',
                    driverName: authUser?.fullName ?? 'Muhammad Asif',
                    driverPhone: authUser?.phone ?? '+923001234567',
                    driverRating: authUser?.rating ?? 4.8,
                    isVerifiedDriver: authUser?.cnicVerified ?? true,
                    proposedRatePkr: double.tryParse(rateCtrl.text.trim()) ?? load.offeredRatePkr,
                    estimatedHours: int.tryParse(hoursCtrl.text.trim()) ?? 24,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await ref.read(firebaseServiceProvider).submitBid(load.id, newBid);
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
        return Consumer(
          builder: (context, ref, _) {
            final bidsAsync = ref.watch(firebaseLoadBidsStreamProvider(load.id));
            final bids = bidsAsync.value ?? [];

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
                                        await ref.read(firebaseServiceProvider).acceptBid(
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
    final authUser = ref.watch(authProvider).userProfile;
    final loadsAsync = ref.watch(firebaseLoadsStreamProvider);
    var loadsList = loadsAsync.value ?? FirebaseService.defaultSampleLoads;

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
        title: Text(l10n.availableLoadsTitle),
        actions: [
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
                      if (val) setState(() => _selectedVehicleFilter = 'all');
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
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loads List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: loadsList.length,
              itemBuilder: (context, index) {
                final load = loadsList[index];
                final contactPhone = load.contactPhone ?? '+923001234567';
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

                            // Route Inspector button
                            IconButton(
                              icon: const Icon(Icons.alt_route, color: AppColors.primary),
                              tooltip: l10n.inspectRoute,
                              onPressed: () => context.push('/route-planner'),
                            ),

                            // Trip Lifecycle progression for assigned driver
                            if (isAssignedToMe || isMyLoad) ...[
                              if (load.status == LoadStatus.assigned)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: Text(isUrdu ? 'سفر شروع کریں' : 'Start Trip'),
                                  onPressed: () async {
                                    await ref.read(firebaseServiceProvider).updateLoadStatus(load.id, LoadStatus.inTransit);
                                  },
                                )
                              else if (load.status == LoadStatus.inTransit)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: Text(isUrdu ? 'مال پہنچ گیا' : 'Mark Delivered'),
                                  onPressed: () async {
                                    await ref.read(firebaseServiceProvider).updateLoadStatus(load.id, LoadStatus.delivered);
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
  }
}
