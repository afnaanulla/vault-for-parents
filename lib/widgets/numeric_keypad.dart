import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;
  final Color? accentColor;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometric = true,
    this.accentColor,
  });

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onTap,
    Color? bgColor,
  }) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: bgColor ?? Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.border, width: 1.2),
        ),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: (accentColor ?? AppColors.primary).withValues(alpha: 0.15),
          highlightColor: (accentColor ?? AppColors.primary).withValues(alpha: 0.08),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildDigit(String digit) {
    return _buildKeyButton(
      onTap: () => onDigitPressed(digit),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigit('1'),
              _buildDigit('2'),
              _buildDigit('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigit('4'),
              _buildDigit('5'),
              _buildDigit('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigit('7'),
              _buildDigit('8'),
              _buildDigit('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bottom Left: Biometric trigger
              showBiometric && onBiometricPressed != null
                  ? _buildKeyButton(
                      bgColor: effectiveAccent.withValues(alpha: 0.08),
                      onTap: onBiometricPressed!,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 36,
                        color: effectiveAccent,
                      ),
                    )
                  : const SizedBox(width: 76, height: 76),
              _buildDigit('0'),
              // Bottom Right: Delete / Backspace
              _buildKeyButton(
                bgColor: AppColors.background,
                onTap: onDeletePressed,
                child: const Icon(
                  Icons.backspace_outlined,
                  size: 26,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
