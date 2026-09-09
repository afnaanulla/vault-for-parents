import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';
import 'jupiter_card.dart';

class MaskedFieldTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final bool isUnmasked;
  final int remainingSeconds;
  final VoidCallback onToggleReveal;
  final Color? accentColor;

  const MaskedFieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.isSensitive,
    required this.isUnmasked,
    this.remainingSeconds = 30,
    required this.onToggleReveal,
    this.accentColor,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.textDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;
    final displayValue = isSensitive && !isUnmasked
        ? '•••• ••••'
        : value;

    return JupiterCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (isSensitive && isUnmasked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-hides in ${remainingSeconds > 0 ? remainingSeconds : 1}s',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  displayValue,
                  style: TextStyle(
                    fontSize: isSensitive && !isUnmasked ? 22 : 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isSensitive && !isUnmasked ? 4.0 : 0.5,
                    fontFamily: isSensitive ? 'monospace' : null,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (isSensitive) ...[
                IconButton(
                  icon: Icon(
                    isUnmasked
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isUnmasked ? AppColors.danger : effectiveAccent,
                    size: 22,
                  ),
                  tooltip: isUnmasked ? 'Hide' : 'Unlock with fingerprint to view',
                  onPressed: onToggleReveal,
                ),
              ],
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Copy',
                onPressed: () => _copyToClipboard(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
