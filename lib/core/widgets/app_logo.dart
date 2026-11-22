import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size = 36,
    this.borderRadius = 8,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Image.asset(
          'assets/truck_link_icon_square.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) {
            return Container(
              color: AppColors.primary,
              child: Icon(
                Icons.local_shipping,
                size: size * 0.6,
                color: AppColors.accent,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppLogoWithTitle extends StatelessWidget {
  final double iconSize;
  final TextStyle? titleStyle;
  final bool isLight;

  const AppLogoWithTitle({
    super.key,
    this.iconSize = 32,
    this.titleStyle,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: iconSize, borderRadius: 8),
        const SizedBox(width: 10),
        Text(
          'Truck Link PK',
          style: titleStyle ??
              TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isLight ? Colors.white : AppColors.textPrimaryLight,
                letterSpacing: 0.8,
              ),
        ),
      ],
    );
  }
}
