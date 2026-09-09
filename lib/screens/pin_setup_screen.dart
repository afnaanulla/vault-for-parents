import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/entries_provider.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pin_dots_indicator.dart';
import 'home_dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _enteredPin = '';
  String _firstEnteredPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  String _errorMessage = '';

  void _onDigit(String digit) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _hasError = false;
      _errorMessage = '';
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _handlePinComplete();
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (!_isConfirming) {
      // Move to confirmation step
      setState(() {
        _firstEnteredPin = _enteredPin;
        _enteredPin = '';
        _isConfirming = true;
      });
    } else {
      // Validate match
      if (_enteredPin == _firstEnteredPin) {
        final auth = context.read<AuthProvider>();
        final profile = auth.currentUser;
        if (profile != null) {
          final success = await auth.setupPin(_enteredPin);
          if (success && mounted) {
            // Preload entries (will be empty on first setup)
            context.read<EntriesProvider>().loadEntries(profile, _enteredPin);

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'PINs do not match. Please try again.';
          _enteredPin = '';
          _firstEnteredPin = '';
          _isConfirming = false;
        });
      }
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            auth.switchUser();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Profile Indicator Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: user?.badgeBgColor ?? AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${user?.avatarEmoji ?? ''} Setting up ${user?.displayName ?? ''}\'s Vault',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isConfirming ? 'Confirm your 4-digit PIN' : 'Create your 4-digit PIN',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Enter the same PIN once more'
                  : 'You will use this PIN or fingerprint to unlock your records',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Dots indicator
            PinDotsIndicator(
              pinLength: _enteredPin.length,
              hasError: _hasError,
              activeColor: accent,
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().shake(duration: 400.ms),

            const Spacer(),

            // Keypad
            NumericKeypad(
              onDigitPressed: _onDigit,
              onDeletePressed: _onDelete,
              showBiometric: false,
              accentColor: accent,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
