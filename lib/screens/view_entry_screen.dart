import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/user_profile.dart';
import '../models/vault_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/entries_provider.dart';
import '../services/biometric_service.dart';
import '../widgets/masked_field_tile.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/pin_dots_indicator.dart';
import 'add_edit_entry_screen.dart';

class ViewEntryScreen extends StatefulWidget {
  final VaultEntry entry;

  const ViewEntryScreen({super.key, required this.entry});

  @override
  State<ViewEntryScreen> createState() => _ViewEntryScreenState();
}

class _ViewEntryScreenState extends State<ViewEntryScreen> {
  late VaultEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  bool _isSecretField(String key) {
    final lower = key.toLowerCase();
    return lower.contains('pin') ||
        lower.contains('mpin') ||
        lower.contains('cvv') ||
        lower.contains('password') ||
        lower.contains('account_number') ||
        lower.contains('ifsc_code') ||
        lower == 'note';
  }

  List<String> _getPairedFields(String key) {
    if (key == 'account_number' || key == 'ifsc_code') {
      return ['account_number', 'ifsc_code'];
    }
    return [key];
  }

  String _formatFieldLabel(String key) {
    switch (key) {
      case 'institution':
        return 'Bank / Institution';
      case 'holder_name':
        return 'Name on Record';
      case 'account_number':
        return 'Account Number';
      case 'ifsc_code':
        return 'IFSC Code';
      case 'branch':
        return 'Branch';
      case 'card_number':
        return 'Card Number';
      case 'expiry':
        return 'Expiry Date';
      case 'cvv':
        return 'CVV Security Code';
      case 'pin':
        return 'Secret PIN';
      case 'mpin':
        return 'App Login MPIN';
      case 'upi_id':
        return 'UPI ID / VPA';
      case 'user_id':
        return 'User ID / Customer ID';
      case 'password':
        return 'Password';
      case 'aadhaar_number':
        return 'Aadhaar Number';
      case 'pan_number':
        return 'PAN Number';
      case 'mobile':
        return 'Linked Mobile';
      case 'dob':
        return 'Date of Birth';
      case 'note':
        return 'Secure Note';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _handleToggleSecret(String fieldKey, String label) async {
    final entriesProvider = context.read<EntriesProvider>();
    final entryId = _currentEntry.id;
    final pairedFields = _getPairedFields(fieldKey);

    // If already unmasked, mask paired fields immediately
    if (entriesProvider.isFieldUnmasked(entryId, fieldKey)) {
      entriesProvider.maskFields(entryId, pairedFields);
      return;
    }

    final authReason = pairedFields.length > 1
        ? 'Account Number & IFSC Code'
        : label;

    // User requirement: Must give biometrics to see this particular PIN/secret!
    final authenticated = await BiometricService.authenticateToRevealSecret(
      fieldName: authReason,
    );

    if (authenticated && mounted) {
      entriesProvider.unmaskFields(entryId, pairedFields, durationSeconds: 30);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$authReason revealed for 30 seconds'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.textDark,
        ),
      );
    } else if (mounted) {
      // Biometrics failed or cancelled: offer PIN confirmation fallback
      _showPinFallbackModal(pairedFields, authReason);
    }
  }

  void _showPinFallbackModal(List<String> pairedFields, String label) {
    String enteredPin = '';
    bool hasError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final auth = context.read<AuthProvider>();
            final user = auth.currentUser ?? UserProfile.father;

            void onDigit(String d) {
              if (enteredPin.length >= 4) return;
              setModalState(() {
                hasError = false;
                enteredPin += d;
              });

              if (enteredPin.length == 4) {
                if (enteredPin == auth.activeSessionPin) {
                  Navigator.of(ctx).pop();
                  context.read<EntriesProvider>().unmaskFields(
                        _currentEntry.id,
                        pairedFields,
                        durationSeconds: 30,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label revealed for 30 seconds'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.textDark,
                    ),
                  );
                } else {
                  setModalState(() {
                    hasError = true;
                    enteredPin = '';
                  });
                }
              }
            }

            void onDelete() {
              if (enteredPin.isNotEmpty) {
                setModalState(() {
                  hasError = false;
                  enteredPin = enteredPin.substring(0, enteredPin.length - 1);
                });
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authorize to view $label',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your 4-digit PIN to unmask this secret',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  PinDotsIndicator(
                    pinLength: enteredPin.length,
                    hasError: hasError,
                    activeColor: user.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  if (hasError)
                    const Text(
                      'Incorrect PIN',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  const SizedBox(height: 16),
                  NumericKeypad(
                    onDigitPressed: onDigit,
                    onDeletePressed: onDelete,
                    showBiometric: false,
                    accentColor: user.primaryColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete "${_currentEntry.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(90, 42),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              final entries = context.read<EntriesProvider>();
              await entries.deleteEntry(
                profile: auth.currentUser ?? UserProfile.father,
                sessionPin: auth.activeSessionPin,
                entryId: _currentEntry.id,
              );
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final entriesProvider = context.watch<EntriesProvider>();
    final user = auth.currentUser ?? UserProfile.father;
    final accent = user.primaryColor;

    // Refresh entry from provider if it was edited
    final matched = entriesProvider.entries
        .where((e) => e.id == _currentEntry.id)
        .toList();
    if (matched.isNotEmpty) {
      _currentEntry = matched.first;
    }

    final catColor = _currentEntry.category.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentEntry.category.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditEntryScreen(existingEntry: _currentEntry),
                ),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _currentEntry.category.icon,
                        color: catColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentEntry.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentEntry.institution.isNotEmpty
                                ? _currentEntry.institution
                                : _currentEntry.category.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Security notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap the 👁️ icon on any secret PIN/password to scan your fingerprint and view it.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Confidential Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Fields List
              ..._currentEntry.fields.entries.map((f) {
                final isSecret = _isSecretField(f.key);
                final label = _formatFieldLabel(f.key);
                final isUnmasked = entriesProvider.isFieldUnmasked(_currentEntry.id, f.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MaskedFieldTile(
                    label: label,
                    value: f.value,
                    isSensitive: isSecret,
                    isUnmasked: isUnmasked,
                    remainingSeconds: entriesProvider.getRemainingSeconds(_currentEntry.id, f.key),
                    accentColor: accent,
                    onToggleReveal: () => _handleToggleSecret(f.key, label),
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
