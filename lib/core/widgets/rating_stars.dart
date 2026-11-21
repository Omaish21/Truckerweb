import 'package:flutter/material.dart';
import '../theme/colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: AppColors.accent),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
