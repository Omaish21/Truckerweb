import 'package:flutter/material.dart';
import '../../../../core/constants/report_categories.dart';
import '../../../../core/theme/colors.dart';

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
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Road report submitted & broadcast to nearby drivers within 20km!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Hazard / سڑک کی خرابی'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Hazard Category / قسم کا انتخاب کریں',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RoadReportCategory.all.map((category) {
                final isSelected = category.id == _selectedCategoryId;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        '${category.nameEn} (${category.nameUr})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: category.color,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryId = category.id);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // GPS Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Captured GPS Coordinates',
                prefixIcon: const Icon(Icons.my_location, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Updated to current device GPS fix.')),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description / تفصیل (اختیاری)',
                hintText: 'e.g., Deep crater on left lane, heavy trucks driving on single lane.',
              ),
            ),

            const SizedBox(height: 16),

            // Camera / Photo Upload
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Attach Photo (Optional / تصویر منسلک کریں)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Broadcast Road Alert / رپورٹ بھیجیں'),
            ),
          ],
        ),
      ),
    );
  }
}
