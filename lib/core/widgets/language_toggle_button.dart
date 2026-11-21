import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/locale_provider.dart';
import '../utils/urdu_text.dart';

class LanguageToggleButton extends ConsumerWidget {
  final bool compact;
  final Color? color;
  final Color? textColor;

  const LanguageToggleButton({
    super.key,
    this.compact = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isUrdu = currentLocale.languageCode == 'ur';

    // Target label: what clicking will change to
    final targetLabel = isUrdu ? 'English' : 'اردو';
    final targetFont = isUrdu ? null : UrduTextUtils.nastaliqStyle(fontSize: 14, height: 1.4);

    return InkWell(
      onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (textColor ?? Colors.white).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: compact ? 16 : 18,
              color: textColor ?? Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              targetLabel,
              style: (targetFont ?? const TextStyle()).copyWith(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
