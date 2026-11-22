import 'package:flutter/material.dart';
import '../../../../core/constants/report_categories.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/voice_input_button.dart';
import '../../../../l10n/app_localizations.dart';

class ReportConditionScreen extends StatefulWidget {
  const ReportConditionScreen({super.key});

  @override
  State<ReportConditionScreen> createState() => _ReportConditionScreenState();
}

class _ReportConditionScreenState extends State<ReportConditionScreen> {
  String _selectedCategoryId = 'broken';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'N-5 Highway, Near Okara Bypass (30.8138° N, 73.4534° E)');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final service = FirebaseService.instance;
      await service.reportHazard(
        categoryId: _selectedCategoryId,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(l10n.hazardBroadcastSuccess),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportRoadHazard),
        actions: const [
          Center(child: LanguageToggleButton(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.selectHazardCategory,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RoadReportCategory.all.map((category) {
                final isSelected = _selectedCategoryId == category.id;
                return ChoiceChip(
                  label: Text(isUrdu ? category.nameUr : category.nameEn),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategoryId = category.id);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.exactLocationLabel,
                prefixIcon: const Icon(Icons.gps_fixed, color: AppColors.danger),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: isUrdu ? 'مائیکروفون دبا کر خطرہ یا سڑک کی صورتحال بولیں...' : l10n.descriptionHint,
                alignLabelWithHint: true,
                suffixIcon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceInputButton(
                      controller: _descriptionController,
                      languageCode: isUrdu ? 'ur' : 'en',
                    ),
                    IconButton(
                      icon: const Icon(Icons.translate, size: 20, color: AppColors.primary),
                      tooltip: isUrdu ? 'ترجمہ کریں' : 'Translate Note',
                      onPressed: () {
                        if (_descriptionController.text.isNotEmpty) {
                          final trans = TranslationService().translate(
                            text: _descriptionController.text,
                            targetLanguageCode: isUrdu ? 'ur' : 'en',
                          );
                          setState(() => _descriptionController.text = trans);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 20, color: AppColors.accent),
                      tooltip: isUrdu ? 'سنیں' : 'Listen',
                      onPressed: () {
                        if (_descriptionController.text.isNotEmpty) {
                          AudioAlertService().speakWarning(
                            text: _descriptionController.text,
                            languageCode: isUrdu ? 'ur' : 'en',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: const Icon(Icons.broadcast_on_personal),
              label: Text(
                l10n.submitHazardButton,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
