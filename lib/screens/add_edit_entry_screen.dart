import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../config/app_colors.dart';
import '../models/user_profile.dart';
import '../models/vault_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/entries_provider.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class AddEditEntryScreen extends StatefulWidget {
  final VaultEntry? existingEntry;
  final EntryCategory? initialCategory;

  const AddEditEntryScreen({
    super.key,
    this.existingEntry,
    this.initialCategory,
  });

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late EntryCategory _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  // Dynamic field controllers
  final Map<String, TextEditingController> _fieldControllers = {};

  // Photo document path
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    if (entry != null) {
      _selectedCategory = entry.category;
      _titleController.text = entry.title;
      _institutionController.text = entry.institution;
      _selectedImagePath = entry.fields['image_path'];
      entry.fields.forEach((k, v) {
        _fieldControllers[k] = TextEditingController(text: v);
      });
    } else {
      _selectedCategory = widget.initialCategory ?? EntryCategory.bankAccount;
    }
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final picker = ImagePicker();
      final response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null && mounted) {
        setState(() {
          _selectedImagePath = response.file!.path;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _institutionController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key) {
    return _fieldControllers.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _pickImage(ImageSource source) async {
    StorageService.isPickingMedia = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked != null) {
        setState(() {
          _selectedImagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera or photos: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      // 800ms buffer ensures Android activity resume transitions complete
      // before re-enabling auto-lock on app backgrounding
      await Future.delayed(const Duration(milliseconds: 800));
      StorageService.isPickingMedia = false;
    }
  }

  Widget _buildPhotoPickerSection({required bool isRequired}) {
    final hasImage = _selectedImagePath != null && _selectedImagePath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isRequired ? 'Document Photo *' : 'Attach Document / Passbook Photo (Optional)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (hasImage)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remove Photo', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _selectedImagePath = null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasImage) ...[
            // Photo Preview Container
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                    ),
                    // Retake Overlay Button
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.75),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: const Text('Retake Photo', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Big Elderly-Friendly Capture Buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_rounded, size: 36, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Use Camera',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 36, color: AppColors.textBody),
                          SizedBox(height: 8),
                          Text(
                            'Upload Photo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'From Gallery',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String fieldKey,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isSecret = false,
    bool isRequired = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    final controller = _getController(fieldKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (isRequired ? ' *' : ''),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textCapitalization: textCapitalization,
            validator: isRequired
                ? (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null
                : null,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              prefixIcon: isSecret
                  ? const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryFields() {
    switch (_selectedCategory) {
      case EntryCategory.bankAccount:
        return [
          _buildField(
            label: 'Bank Name',
            fieldKey: 'institution',
            hint: 'e.g. HDFC Bank, SBI, ICICI, SIB',
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            label: 'Account Holder Name',
            fieldKey: 'holder_name',
            hint: 'Full name as per bank records',
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            label: 'Account Number',
            fieldKey: 'account_number',
            hint: 'e.g. 50100234567890',
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          _buildField(
            label: 'IFSC Code',
            fieldKey: 'ifsc_code',
            hint: 'e.g. HDFC0001234',
            textCapitalization: TextCapitalization.characters,
            isRequired: true,
          ),
          _buildField(
            label: 'Branch Name',
            fieldKey: 'branch',
            hint: 'e.g. Indiranagar, Bengaluru',
            textCapitalization: TextCapitalization.words,
          ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'App Login MPIN (Secret)',
                  fieldKey: 'mpin',
                  hint: '4 or 6 digit MPIN',
                  keyboardType: TextInputType.number,
                  isSecret: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildField(
                  label: 'ATM PIN (Secret)',
                  fieldKey: 'pin',
                  hint: '4-digit ATM PIN',
                  keyboardType: TextInputType.number,
                  isSecret: true,
                ),
              ),
            ],
          ),
          _buildField(
            label: 'NetBanking Customer ID / User ID',
            fieldKey: 'user_id',
            hint: 'e.g. 84920193',
          ),
          _buildField(
            label: 'NetBanking Password (Secret)',
            fieldKey: 'password',
            hint: 'Login Password',
            isSecret: true,
          ),
        ];

      case EntryCategory.card:
        return [
          _buildField(
            label: 'Bank / Card Issuer',
            fieldKey: 'institution',
            hint: 'e.g. HDFC Millennia, SBI SimplyCLICK',
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            label: 'Name on Card',
            fieldKey: 'holder_name',
            hint: 'Cardholder full name',
            textCapitalization: TextCapitalization.characters,
          ),
          _buildField(
            label: 'Card Number',
            fieldKey: 'card_number',
            hint: '16-digit card number',
            keyboardType: TextInputType.number,
            formatters: [CardNumberFormatter()],
            isRequired: true,
          ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Expiry Date',
                  fieldKey: 'expiry',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.datetime,
                  formatters: [ExpiryDateFormatter()],
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildField(
                  label: 'CVV (Secret)',
                  fieldKey: 'cvv',
                  hint: '3 digits',
                  keyboardType: TextInputType.number,
                  isSecret: true,
                  isRequired: true,
                ),
              ),
            ],
          ),
          _buildField(
            label: 'ATM PIN (Secret)',
            fieldKey: 'pin',
            hint: '4-digit ATM PIN',
            keyboardType: TextInputType.number,
            isSecret: true,
          ),
        ];

      case EntryCategory.upiPin:
        return [
          _buildField(
            label: 'App / Bank Name',
            fieldKey: 'institution',
            hint: 'e.g. Google Pay, PhonePe, Paytm, BHIM, SIB Mirror+',
            isRequired: true,
          ),
          _buildField(
            label: 'UPI ID / VPA',
            fieldKey: 'upi_id',
            hint: 'e.g. mobile@upi or name@okaxis',
            keyboardType: TextInputType.emailAddress,
          ),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'UPI PIN (Secret)',
                  fieldKey: 'pin',
                  hint: '4 or 6 digit PIN',
                  keyboardType: TextInputType.number,
                  isSecret: true,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildField(
                  label: 'App Login MPIN (Secret)',
                  fieldKey: 'mpin',
                  hint: 'Login MPIN',
                  keyboardType: TextInputType.number,
                  isSecret: true,
                ),
              ),
            ],
          ),
          _buildField(
            label: 'User ID / Login ID',
            fieldKey: 'user_id',
            hint: 'App Username or Customer ID',
          ),
          _buildField(
            label: 'App Password (Secret)',
            fieldKey: 'password',
            hint: 'Login Password',
            isSecret: true,
          ),
        ];

      case EntryCategory.aadhaar:
        return [
          _buildField(
            label: 'Full Name on Aadhaar',
            fieldKey: 'holder_name',
            hint: 'Name as printed on Aadhaar',
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            label: 'Aadhaar Number',
            fieldKey: 'aadhaar_number',
            hint: '12-digit number (e.g. 1234 5678 9012)',
            keyboardType: TextInputType.number,
            formatters: [AadhaarNumberFormatter()],
            isRequired: true,
          ),
          _buildField(
            label: 'Linked Mobile Number',
            fieldKey: 'mobile',
            hint: '10-digit phone number',
            keyboardType: TextInputType.phone,
          ),
          _buildField(
            label: 'Date of Birth',
            fieldKey: 'dob',
            hint: 'DD/MM/YYYY',
            keyboardType: TextInputType.datetime,
            formatters: [DateOfBirthFormatter()],
          ),
        ];

      case EntryCategory.pan:
        return [
          _buildField(
            label: 'Full Name on PAN Card',
            fieldKey: 'holder_name',
            hint: 'Name as printed on PAN',
            isRequired: true,
            textCapitalization: TextCapitalization.characters,
          ),
          _buildField(
            label: 'PAN Number',
            fieldKey: 'pan_number',
            hint: '10 characters (e.g. ABCDE1234F)',
            textCapitalization: TextCapitalization.characters,
            isRequired: true,
          ),
        ];

      case EntryCategory.document:
        return [
          _buildPhotoPickerSection(isRequired: true),
          _buildField(
            label: 'Document Name (Searchable)',
            fieldKey: 'document_name',
            hint: 'e.g. SBI Passbook, Aadhaar Front, Electricity Bill',
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            label: 'Organization / Bank / Issuer',
            fieldKey: 'institution',
            hint: 'e.g. State Bank of India, UIDAI, Income Tax',
            textCapitalization: TextCapitalization.words,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Notes / Account No (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _getController('note'),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add any reference numbers or helpful notes...',
                  ),
                ),
              ],
            ),
          ),
        ];

      case EntryCategory.secureNote:
        return [
          _buildPhotoPickerSection(isRequired: false),
          _buildField(
            label: 'Locker / Account / Reference',
            fieldKey: 'institution',
            hint: 'e.g. SBI Locker #42, Home Safe',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Secret Content / PINs *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _getController('note'),
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter note content' : null,
                  decoration: const InputDecoration(
                    hintText: 'Enter secret combination, codes, or instructions...',
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == EntryCategory.document &&
        (_selectedImagePath == null || _selectedImagePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or upload a photo of the document first.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final entriesProvider = context.read<EntriesProvider>();
    final user = auth.currentUser ?? UserProfile.father;
    final pin = auth.activeSessionPin;

    final fields = <String, String>{};
    for (final entry in _fieldControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        fields[entry.key] = entry.value.text.trim();
      }
    }

    // Save sandboxed photo if present
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
      final existingPath = widget.existingEntry?.fields['image_path'];
      if (_selectedImagePath != existingPath) {
        final savedPath = await auth.storageService.saveDocumentPhoto(user, _selectedImagePath!);
        fields['image_path'] = savedPath;
        if (existingPath != null) {
          await auth.storageService.deleteDocumentPhoto(existingPath);
        }
      } else {
        fields['image_path'] = existingPath!;
      }
    } else {
      final existingPath = widget.existingEntry?.fields['image_path'];
      if (existingPath != null) {
        await auth.storageService.deleteDocumentPhoto(existingPath);
      }
    }

    final institution = fields['institution'] ?? _institutionController.text.trim();
    final docName = fields['document_name'];
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (docName != null && docName.isNotEmpty)
            ? docName
            : institution.isNotEmpty
                ? institution
                : _selectedCategory.displayName;

    final isNew = widget.existingEntry == null;
    final entry = VaultEntry(
      id: widget.existingEntry?.id ?? const Uuid().v4(),
      category: _selectedCategory,
      title: title,
      institution: institution,
      fields: fields,
      isFavorite: widget.existingEntry?.isFavorite ?? false,
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isNew) {
      success = await entriesProvider.addEntry(
        profile: user,
        sessionPin: pin,
        entry: entry,
      );
    } else {
      success = await entriesProvider.updateEntry(
        profile: user,
        sessionPin: pin,
        updatedEntry: entry,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Entry encrypted & saved!' : 'Entry updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser ?? UserProfile.father;
    final accent = user.primaryColor;
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vault Entry' : 'Add New Entry'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Picker (if adding new)
                if (!isEditing) ...[
                  const Text(
                    'Select Type of Entry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EntryCategory.values.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat.displayName),
                        selected: isSelected,
                        selectedColor: cat.color.withValues(alpha: 0.15),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? cat.color : AppColors.border,
                          width: 1.2,
                        ),
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? cat.color : AppColors.textMuted,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? cat.color : AppColors.textBody,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Title field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Title (Friendly Nickname)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Father\'s Main HDFC Account',
                        prefixIcon: Icon(
                          _selectedCategory.icon,
                          size: 20,
                          color: _selectedCategory.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Category Fields
                ..._buildCategoryFields(),

                const SizedBox(height: 24),

                // Big Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Encrypt & Save in Vault',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
