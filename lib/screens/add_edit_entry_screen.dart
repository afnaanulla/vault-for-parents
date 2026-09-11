import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'photo_view_screen.dart';
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

  // Photo document paths (multi-page support)
  List<String> _selectedImagePaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    if (entry != null) {
      _selectedCategory = entry.category;
      _titleController.text = entry.title;
      _institutionController.text = entry.institution;
      _selectedImagePaths = List<String>.from(entry.imagePaths);
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
          if (!_selectedImagePaths.contains(response.file!.path)) {
            _selectedImagePaths.add(response.file!.path);
          }
        });
      }
      if (response.files != null && mounted) {
        setState(() {
          for (final f in response.files!) {
            if (!_selectedImagePaths.contains(f.path)) {
              _selectedImagePaths.add(f.path);
            }
          }
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

  Future<void> _pickCameraImage() async {
    StorageService.isPickingMedia = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked != null) {
        setState(() {
          _selectedImagePaths.add(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      StorageService.isPickingMedia = false;
    }
  }

  Future<void> _pickGalleryImages() async {
    StorageService.isPickingMedia = true;
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (pickedList.isNotEmpty) {
        setState(() {
          for (final picked in pickedList) {
            if (!_selectedImagePaths.contains(picked.path)) {
              _selectedImagePaths.add(picked.path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open photos gallery: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      StorageService.isPickingMedia = false;
    }
  }

  Widget _buildPhotoPickerSection({required bool isRequired}) {
    final hasImages = _selectedImagePaths.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isRequired ? 'Document Photos *' : 'Attach Document Photos (Optional)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (hasImages) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedImagePaths.length} ${_selectedImagePaths.length == 1 ? 'page' : 'pages'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (hasImages)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _selectedImagePaths.clear();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasImages) ...[
            // Horizontal Photo Strip
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImagePaths.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final path = _selectedImagePaths[index];
                  final file = File(path);

                  return Container(
                    width: 135,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Tap to preview
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewScreen(
                                    imagePaths: _selectedImagePaths,
                                    initialIndex: index,
                                    title: 'Document Preview',
                                  ),
                                ),
                              );
                            },
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                              ),
                            ),
                          ),

                          // Page Badge (Top-Left)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Page ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Remove single page button (Top-Right)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImagePaths.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),

                          // Tap to view hint at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              color: Colors.black.withValues(alpha: 0.55),
                              child: const Center(
                                child: Text(
                                  'Tap to Zoom',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Secondary Buttons to Add More Pages
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pickCameraImage,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: const Text('Add via Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pickGalleryImages,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Add from Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Big Elderly-Friendly Capture Buttons (Initial State)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickCameraImage,
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
                    onTap: _pickGalleryImages,
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
                            'Upload Photos',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select Multiple',
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

    if (_selectedCategory == EntryCategory.document && _selectedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or upload at least one photo of the document first.'),
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

    // Save sandboxed photos if present (multi-page support)
    final oldPaths = widget.existingEntry?.imagePaths ?? [];
    final finalSandboxedPaths = <String>[];

    for (final path in _selectedImagePaths) {
      if (oldPaths.contains(path) && File(path).existsSync()) {
        // Already sandboxed in persistent storage
        finalSandboxedPaths.add(path);
      } else {
        // Newly added temporary image: copy into private sandboxed storage
        final savedPath = await auth.storageService.saveDocumentPhoto(user, path);
        finalSandboxedPaths.add(savedPath);
      }
    }

    // Clean up any removed photos from disk to prevent dangling storage
    for (final oldPath in oldPaths) {
      if (!finalSandboxedPaths.contains(oldPath)) {
        await auth.storageService.deleteDocumentPhoto(oldPath);
      }
    }

    if (finalSandboxedPaths.isNotEmpty) {
      fields['image_paths'] = json.encode(finalSandboxedPaths);
      fields['image_path'] = finalSandboxedPaths.first;
    } else {
      fields.remove('image_paths');
      fields.remove('image_path');
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
