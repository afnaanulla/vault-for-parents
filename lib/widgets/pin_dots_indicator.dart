import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int maxLength;
  final bool hasError;
  final Color? activeColor;

  const PinDotsIndicator({
    super.key,
    required this.pinLength,
    this.maxLength = 4,
    this.hasError = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = hasError
        ? AppColors.danger
        : (activeColor ?? AppColors.primary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? effectiveActiveColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? effectiveActiveColor : AppColors.border,
              width: 2.2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: effectiveActiveColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
