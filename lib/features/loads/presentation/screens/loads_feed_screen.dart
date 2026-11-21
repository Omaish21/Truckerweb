import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/truck_icon.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.availableLoadsTitle),
        actions: [
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
                              '${load.goodsType ?? l10n.goodsGeneral} • ${l10n.tonsUnit(load.weightTons.toInt().toString())}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.statusOpen,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.offeredRateLabel,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 2),
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
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => context.push('/route-planner'),
                        icon: const Icon(Icons.alt_route, size: 16),
                        label: Text(l10n.inspectRoute),
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
