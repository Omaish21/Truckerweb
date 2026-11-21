import 'package:flutter/material.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/theme/colors.dart';

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
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Load posted successfully! PostGIS search activated for nearby drivers.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Load / نیا مال بک کریں'),
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
                decoration: const InputDecoration(
                  labelText: 'Pickup City & Area / روانگی کا مقام',
                  prefixIcon: Icon(Icons.trip_origin, color: AppColors.primary),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destController,
                decoration: const InputDecoration(
                  labelText: 'Drop-off City & Destination / منزل',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.accent),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // Vehicle Type Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Required / گاڑی کی قسم',
                  prefixIcon: Icon(Icons.local_shipping, color: AppColors.primary),
                ),
                items: VehicleType.all.map((v) {
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.nameEn} (${v.nameUr})'),
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
                      decoration: const InputDecoration(
                        labelText: 'Weight (Tons) / وزن',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (Feet) / اونچائی',
                        prefixIcon: Icon(Icons.height),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Offered Rate
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offered Rate (PKR) / کرایہ (روپے)',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppColors.success),
                  hintText: 'e.g. 250000',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // Goods type chips
              const Text('Goods Type / مال کی قسم:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['general', 'fragile', 'hazardous', 'refrigerated'].map((type) {
                  final isSelected = _goodsType == type;
                  return ChoiceChip(
                    label: Text(type.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    onSelected: (val) {
                      if (val) setState(() => _goodsType = type);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Post Load & Find Drivers / لوڈ شائع کریں'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
