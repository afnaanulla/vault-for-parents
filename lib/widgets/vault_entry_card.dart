import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/vault_entry.dart';
import 'jupiter_card.dart';

class VaultEntryCard extends StatelessWidget {
  final VaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const VaultEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onFavoriteToggle,
  });

  String _getSummaryText() {
    if (entry.category == EntryCategory.document) {
      if (entry.institution.isNotEmpty) return 'Document • ${entry.institution}';
      return 'Photo Document • Tap to view & zoom';
    }
    if (entry.fields.containsKey('account_number')) {
      final acc = entry.fields['account_number']!;
      final last4 = acc.length > 4 ? acc.substring(acc.length - 4) : acc;
      return 'Account: •••• $last4';
    }
    if (entry.fields.containsKey('card_number')) {
      final card = entry.fields['card_number']!;
      final last4 = card.length > 4 ? card.substring(card.length - 4) : card;
      return 'Card: •••• $last4';
    }
    if (entry.fields.containsKey('aadhaar_number')) {
      final aadh = entry.fields['aadhaar_number']!;
      final last4 = aadh.length > 4 ? aadh.substring(aadh.length - 4) : aadh;
      return 'Aadhaar: •••• $last4';
    }
    if (entry.fields.containsKey('pan_number')) {
      return 'PAN: ${entry.fields['pan_number']}';
    }
    if (entry.fields.containsKey('pin')) {
      return 'PIN: Protected with Biometrics';
    }
    return entry.institution.isNotEmpty ? entry.institution : 'Secure Details';
  }

  @override
  Widget build(BuildContext context) {
    final catColor = entry.category.color;
    final imagePaths = entry.imagePaths;
    final hasPhoto = imagePaths.isNotEmpty && File(imagePaths.first).existsSync();

    return JupiterCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Category Icon or Photo Thumbnail Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasPhoto
                      ? Image.file(
                          File(imagePaths.first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            entry.category.icon,
                            color: catColor,
                            size: 24,
                          ),
                        )
                      : Icon(
                          entry.category.icon,
                          color: catColor,
                          size: 24,
                        ),
                ),
                if (imagePaths.length > 1)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${imagePaths.length}p',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (entry.isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getSummaryText(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight,
            size: 22,
          ),
        ],
      ),
    );
  }
}
