import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../widgets/jupiter_card.dart';
import 'auth_screen.dart';
import 'pin_setup_screen.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  void _handleSelectUser(BuildContext context, UserProfile profile) {
    final auth = context.read<AuthProvider>();
    auth.selectProfile(profile, autoPromptBiometric: false);

    if (auth.status == AuthStatus.pinRequired) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Widget _buildProfileCard(BuildContext context, UserProfile profile) {
    return JupiterCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      onTap: () => _handleSelectUser(context, profile),
      child: Row(
        children: [
          // Emoji avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: profile.badgeBgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: profile.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                profile.avatarEmoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '100% Isolated & Encrypted',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Arrow icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: profile.badgeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: profile.primaryColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_person_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Zero Knowledge Vault',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().moveY(begin: -10, end: 0),
              const SizedBox(height: 14),
              const Text(
                'Who is using the vault?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              const Text(
                'Select your profile to view your personal banking and secret details.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 36),

              // Profiles
              _buildProfileCard(context, UserProfile.father)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .moveY(begin: 15, end: 0),
              const SizedBox(height: 16),
              _buildProfileCard(context, UserProfile.mother)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .moveY(begin: 15, end: 0),

              const Spacer(),

              // Privacy reassurance
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Neither profile can see the other\'s details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
