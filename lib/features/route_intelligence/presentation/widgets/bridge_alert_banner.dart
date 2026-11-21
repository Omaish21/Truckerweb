import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/route_models.dart';

class BridgeAlertBanner extends StatelessWidget {
  final BridgeClearanceAlert alert;
  final VoidCallback? onRerouteTap;

  const BridgeAlertBanner({
    super.key,
    required this.alert,
    this.onRerouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ CRITICAL: LOW BRIDGE AHEAD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'خبردار: آگے پل کی اونچائی کم ہے',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${alert.distanceAheadKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Bridge Clearance',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '${alert.clearanceHeightFt.toStringAsFixed(1)} ft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                Column(
                  children: [
                    const Text(
                      'Your Truck Height',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '${alert.truckHeightFt.toStringAsFixed(1)} ft',
                      style: const TextStyle(
                        color: Color(0xFFFEF08A),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                Column(
                  children: [
                    const Text(
                      'Deficit',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '-${alert.differenceFt.toStringAsFixed(1)} ft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Location: ${alert.bridgeName} (${alert.roadSegment})',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRerouteTap != null)
                ElevatedButton.icon(
                  onPressed: onRerouteTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.alt_route, size: 16),
                  label: const Text(
                    'REROUTE NOW',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
