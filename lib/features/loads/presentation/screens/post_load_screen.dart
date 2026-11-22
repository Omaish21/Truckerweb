import 'package:flutter/material.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/language_toggle_button.dart';
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
  final _originController = TextEditingController(text: 'Lahore (Badami Bagh)');
  final _destController = TextEditingController(text: 'Karachi (Port Qasim)');
  final _weightController = TextEditingController(text: '35');
  final _heightController = TextEditingController(text: '15.2');
  final _rateController = TextEditingController(text: '245000');
  final _notesController = TextEditingController();
  String _selectedVehicleId = '22_wheeler';
  String _goodsType = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
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
              // Origin & Destination
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: l10n.pickupLocationLabel,
                  prefixIcon: const Icon(Icons.trip_origin, color: AppColors.primary),
                ),
                validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destController,
                decoration: InputDecoration(
                  labelText: l10n.dropoffLocationLabel,
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.accent),
                ),
                validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
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
                  if (val != null) setState(() => _selectedVehicleId = val);
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

              // Offered Rate
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.offeredRateLabel,
                  prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.success),
                ),
                validator: (val) => val == null || val.isEmpty ? l10n.requiredField : null,
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
