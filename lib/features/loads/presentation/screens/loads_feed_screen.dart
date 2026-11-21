import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/truck_icon.dart';
import '../../domain/load_model.dart';

class LoadsFeedScreen extends StatelessWidget {
  const LoadsFeedScreen({super.key});

  List<LoadModel> get _sampleLoads => [
    LoadModel(
      id: 'load-1',
      ownerId: 'own-1',
      originCity: 'Lahore (Badami Bagh)',
      destinationCity: 'Karachi (Port Qasim)',
      vehicleTypeRequired: '22_wheeler',
      weightTons: 35.0,
      heightFt: 15.2,
      goodsType: 'General Cargo',
      offeredRatePkr: 245000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    LoadModel(
      id: 'load-2',
      ownerId: 'own-2',
      originCity: 'Faisalabad (Industrial Area)',
      destinationCity: 'Rawalpindi (I-9 Sector)',
      vehicleTypeRequired: '10_wheeler',
      weightTons: 16.0,
      heightFt: 13.5,
      goodsType: 'Textile Yarn',
      offeredRatePkr: 85000,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    LoadModel(
      id: 'load-3',
      ownerId: 'own-3',
      originCity: 'Multan (Chowk Kumharan)',
      destinationCity: 'Quetta (Eastern Bypass)',
      vehicleTypeRequired: 'container',
      weightTons: 28.0,
      heightFt: 14.8,
      goodsType: 'Agricultural Produce',
      offeredRatePkr: 190000,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LoadModel(
      id: 'load-4',
      ownerId: 'own-4',
      originCity: 'Karachi (S.I.T.E)',
      destinationCity: 'Peshawar (Hayatabad)',
      vehicleTypeRequired: 'tanker',
      weightTons: 40.0,
      goodsType: 'Industrial Solvents',
      offeredRatePkr: 320000,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Loads / لوڈ مارکیٹ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post New Load',
            onPressed: () => context.push('/post-load'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Post Load / مال بک کریں', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/post-load'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sampleLoads.length,
        itemBuilder: (context, index) {
          final load = _sampleLoads[index];
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
                            Text(
                              'Goods: ${load.goodsType ?? "General"} • ${AppFormatters.formatWeight(load.weightTons)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatPkr(load.offeredRatePkr),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Fixed Rate',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (load.heightFt != null)
                        Text(
                          'Height: ${load.heightFt} ft (Checked for Low Bridges)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.push('/route-planner'),
                            icon: const Icon(Icons.route, size: 16),
                            label: const Text('Check Bridges', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Application sent to load owner! Direct call enabled.'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Apply / رابطہ', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
