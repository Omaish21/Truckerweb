import 'package:flutter/material.dart';
import '../../../../core/ai/trucklink_ai_service.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/location_search_bar.dart';
import '../../../../core/widgets/voice_input_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/load_model.dart';

class PostLoadScreen extends StatefulWidget {
  const PostLoadScreen({super.key});

  @override
  State<PostLoadScreen> createState() => _PostLoadScreenState();
}

class _PostLoadScreenState extends State<PostLoadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _weightController = TextEditingController(text: '20');
  final _heightController = TextEditingController(text: '12');
  final _rateController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedVehicleId = '22_wheeler';
  String _goodsType = 'general';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final userPhone = FirebaseService.instance.auth?.currentUser?.phoneNumber;
    if (userPhone != null && userPhone.isNotEmpty) {
      _contactPhoneController.text = AppFormatters.formatPakistaniPhoneNumber(userPhone);
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _rateController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _checkAndEstimateRate() {
    if (_originController.text.trim().isNotEmpty &&
        _destController.text.trim().isNotEmpty) {
      _estimateRateWithAi(silent: true);
    }
  }

  void _estimateRateWithAi({bool silent = false}) {
    final origin = _originController.text.trim();
    final dest = _destController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 15.0;
    final vehicle = _selectedVehicleId;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    if (origin.isEmpty || dest.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentOrange,
            content: Text(
              isUrdu
                  ? 'برائے مہربانی پہلے مقام روانگی اور منزل منتخب کریں۔'
                  : 'Please specify pickup and destination locations first.',
            ),
          ),
        );
      }
      return;
    }

    final est = TruckLinkAiService.instance.predictRate(
      origin: origin,
      destination: dest,
      vehicleType: vehicle,
      weightTons: weight,
    );

    setState(() {
      _rateController.text = est.recommendedRatePkr.round().toString();
    });

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF6A11CB),
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'اے آئی تخمینہ: ${AppFormatters.formatPkr(est.recommendedRatePkr)} (ڈیزل: ${est.estimatedDieselLiters.toStringAsFixed(0)} لیٹر | ٹول: ${AppFormatters.formatPkr(est.estimatedTollCostPkr)})'
                      : 'AI Market Estimate: ${AppFormatters.formatPkr(est.recommendedRatePkr)} (${est.estimatedDieselLiters.toStringAsFixed(0)}L diesel | ${AppFormatters.formatPkr(est.estimatedTollCostPkr)} tolls)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final service = FirebaseService.instance;
        final currentUid = service.auth?.currentUser?.uid ?? 'guest-owner';
        final newLoad = LoadModel(
          id: '',
          ownerId: currentUid,
          originCity: _originController.text.trim(),
          destinationCity: _destController.text.trim(),
          vehicleTypeRequired: _selectedVehicleId,
          weightTons: double.tryParse(_weightController.text.trim()) ?? 10.0,
          heightFt: double.tryParse(_heightController.text.trim()),
          goodsType: _goodsType,
          offeredRatePkr: double.tryParse(_rateController.text.trim()) ?? 50000.0,
          contactPhone: _contactPhoneController.text.trim().isNotEmpty
              ? _contactPhoneController.text.trim()
              : (service.auth?.currentUser?.phoneNumber ?? ''),
          createdAt: DateTime.now(),
        );

        await service.postLoad(newLoad);

        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(l10n.postLoadSuccess),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text('Error: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28, borderRadius: 6),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.postNewLoad,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          Center(child: LanguageToggleButton(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Origin Pickup Location (Google Maps Places Search & Logistics Hubs)
              LocationSearchBar(
                label: l10n.pickupLocationLabel,
                hintText: isUrdu
                    ? 'شہر، پورٹ یا اڈا تلاش کریں (مثلاً بادامی باغ، پورٹ قاسم)...'
                    : 'Search city, dry port, or truck stand (e.g. Badami Bagh, Port Qasim)...',
                controller: _originController,
                leadingIcon: Icons.trip_origin,
                iconColor: AppColors.primary,
                validator: (val) => val == null || val.trim().isEmpty ? l10n.requiredField : null,
                quickHubs: const [
                  'Lahore (Badami Bagh)',
                  'Karachi Port (KPT)',
                  'Port Qasim',
                  'Faisalabad Dry Port',
                  'Multan (Chowk Kumharan)',
                  'Sialkot Dry Port',
                  'Peshawar (Chamkani)',
                ],
                onSelected: (val) => _checkAndEstimateRate(),
                onChanged: (val) => _checkAndEstimateRate(),
              ),

              const SizedBox(height: 16),

              // Destination Drop-off Location (Google Maps Places Search & Logistics Hubs)
              LocationSearchBar(
                label: l10n.dropoffLocationLabel,
                hintText: isUrdu
                    ? 'منزل کا شہر، پورٹ یا اڈا تلاش کریں (مثلاً چوک کمہاراں، ایسٹرن بائی پاس)...'
                    : 'Search destination city, port, or hub (e.g. Chowk Kumharan, Eastern Bypass)...',
                controller: _destController,
                leadingIcon: Icons.location_on,
                iconColor: AppColors.accentOrange,
                validator: (val) => val == null || val.trim().isEmpty ? l10n.requiredField : null,
                quickHubs: const [
                  'Karachi (Port Qasim)',
                  'Lahore (Badami Bagh)',
                  'Quetta (Eastern Bypass)',
                  'Peshawar (Chamkani)',
                  'Rawalpindi / Islamabad',
                  'Gwadar Deep Sea Port',
                  'Sukkur (CPEC)',
                ],
                onSelected: (val) => _checkAndEstimateRate(),
                onChanged: (val) => _checkAndEstimateRate(),
              ),

              const SizedBox(height: 16),

              // Vehicle Type Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                decoration: InputDecoration(
                  labelText: l10n.vehicleRequiredLabel,
                  prefixIcon: const Icon(Icons.local_shipping, color: AppColors.primary),
                ),
                items: VehicleType.all.map((v) {
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text(isUrdu ? v.nameUr : v.nameEn),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedVehicleId = val);
                    _checkAndEstimateRate();
                  }
                },
              ),

              const SizedBox(height: 16),

              // Weight & Height
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.loadWeightLabel,
                        prefixIcon: const Icon(Icons.scale_outlined),
                      ),
                      validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
                      onChanged: (_) => _checkAndEstimateRate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.truckHeightLabel,
                        prefixIcon: const Icon(Icons.height_outlined),
                      ),
                      validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Goods Category
              DropdownButtonFormField<String>(
                initialValue: _goodsType,
                decoration: InputDecoration(
                  labelText: l10n.goodsTypeLabel,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 'general', child: Text(l10n.goodsGeneral)),
                  DropdownMenuItem(value: 'textile', child: Text(l10n.goodsTextile)),
                  DropdownMenuItem(value: 'agri', child: Text(l10n.goodsAgri)),
                  DropdownMenuItem(value: 'chemical', child: Text(l10n.goodsChemical)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _goodsType = val);
                },
              ),

              const SizedBox(height: 16),

              // Offered Rate with AI Predictor
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.offeredRateLabel,
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.success),
                      ),
                      validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                    label: Text(
                      isUrdu ? 'اے آئی ریٹ' : 'AI Rate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _estimateRateWithAi(silent: false),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Contact Phone Number for Drivers & Transporters
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PakistaniPhoneInputFormatter()],
                decoration: InputDecoration(
                  labelText: isUrdu
                      ? 'رابطہ فون نمبر (ڈرائیورز اس نمبر پر کال یا واٹس ایپ کریں گے)'
                      : 'Contact Phone Number (Drivers will call or WhatsApp here)',
                  hintText: '+92 308 750 2250',
                  prefixIcon: const Icon(Icons.phone_enabled, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isUrdu
                        ? 'برائے مہربانی رابطہ نمبر درج کریں'
                        : 'Please provide a valid contact phone number';
                  }
                  return AppValidators.validatePhone(val);
                },
              ),

              const SizedBox(height: 16),

              // Dictated Cargo Notes / Special Instructions
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isUrdu ? 'کارگو نوٹس اور ہدایات (آواز سے لکھیں)' : 'Cargo Notes (Voice dictation supported)',
                  hintText: isUrdu ? 'مائیکروفون دبا کر بولیں...' : 'Tap mic to dictate notes...',
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceInputButton(
                        controller: _notesController,
                        languageCode: isUrdu ? 'ur' : 'en',
                      ),
                      IconButton(
                        icon: const Icon(Icons.translate, size: 20, color: AppColors.accent),
                        tooltip: isUrdu ? 'ترجمہ کریں' : 'Translate Note',
                        onPressed: () {
                          if (_notesController.text.isNotEmpty) {
                            final translated = TranslationService().translate(
                              text: _notesController.text,
                              targetLanguageCode: isUrdu ? 'ur' : 'en',
                            );
                            setState(() => _notesController.text = translated);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.submitLoadButton,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
