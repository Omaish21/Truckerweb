import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TruckIcon extends StatelessWidget {
  final String vehicleType;
  final double size;
  final Color? color;

  const TruckIcon({
    super.key,
    required this.vehicleType,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (vehicleType) {
      case 'tanker':
        iconData = Icons.local_gas_station_outlined;
        break;
      case 'container':
        iconData = Icons.inventory_2_outlined;
        break;
      case '22_wheeler':
        iconData = Icons.fire_truck_outlined;
        break;
      case 'mazda':
        iconData = Icons.local_shipping_outlined;
        break;
      default:
        iconData = Icons.local_shipping;
    }

    return Container(
      padding: EdgeInsets.all(size * 0.25),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: size,
        color: color ?? AppColors.primary,
      ),
    );
  }
}
