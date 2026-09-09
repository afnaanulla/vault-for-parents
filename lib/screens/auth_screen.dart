import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/entries_provider.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pin_dots_indicator.dart';
import 'home_dashboard_screen.dart';
import 'user_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _enteredPin = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Auto prompt biometric on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometric();
    });
  }

  Future<void> _triggerBiometric() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.attemptBiometricUnlock();
    if (success && mounted) {
      _onUnlockSuccess();
    }
  }

  void _onUnlockSuccess() {
    final auth = context.read<AuthProvider>();
    final entriesProvider = context.read<EntriesProvider>();
    if (auth.currentUser != null && auth.activeSessionPin.isNotEmpty) {
      entriesProvider.loadEntries(auth.currentUser!, auth.activeSessionPin);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        (route) => false,
      );
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      final auth = context.read<AuthProvider>();
      final ok = auth.unlockWithPin(_enteredPin);
      if (ok) {
        _onUnlockSuccess();
      } else {
        setState(() {
          _hasError = true;
          _enteredPin = '';
        });
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final accent = user?.primaryColor ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Switch Profile',
          onPressed: () {
            auth.switchUser();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              auth.switchUser();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.people_outline, size: 18),
            label: const Text('Switch User'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Avatar
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: user?.badgeBgColor ?? AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.avatarEmoji ?? '🔒',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 14),

            // Profile Greeting
            Text(
              'Welcome, ${user?.displayName ?? 'User'}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use Fingerprint or enter 4-digit PIN',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // PIN Dots
            PinDotsIndicator(
              pinLength: _enteredPin.length,
              hasError: _hasError,
              activeColor: accent,
            ),
            const SizedBox(height: 12),

            // Error or Biometric Shortcut button
            if (auth.authError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  auth.authError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().shake(duration: 400.ms)
            else if (auth.isBiometricSupported)
              GestureDetector(
                onTap: _triggerBiometric,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 18, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to scan fingerprint',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),

            const Spacer(),

            // Numeric Keypad
            NumericKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              onBiometricPressed: _triggerBiometric,
              showBiometric: auth.isBiometricSupported,
              accentColor: accent,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
