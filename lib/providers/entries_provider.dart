import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/vault_entry.dart';
import '../services/storage_service.dart';

class EntriesProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<VaultEntry> _entries = [];
  String _searchQuery = '';
  EntryCategory? _selectedCategory;
  bool _isLoading = false;

  // Track unmasked sensitive fields (key: "$entryId-$fieldKey")
  final Set<String> _unmaskedFields = {};
  final Map<String, Timer> _unmaskTimers = {};

  EntriesProvider(this._storageService);

  List<VaultEntry> get entries => List.unmodifiable(_entries);
  String get searchQuery => _searchQuery;
  EntryCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  /// Fast in-memory search and category filtered list
  List<VaultEntry> get filteredEntries {
    return _entries.where((entry) {
      if (_selectedCategory != null && entry.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty && !entry.matchesSearch(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Total count for active user
  int get totalCount => _entries.length;

  /// Loads entries for authenticated profile using session PIN
  void loadEntries(UserProfile profile, String sessionPin) {
    _isLoading = true;
    notifyListeners();

    _entries = _storageService.loadUserEntries(profile, sessionPin);
    _storageService.updateEntryCount(profile, _entries.length);

    _isLoading = false;
    notifyListeners();
  }

  /// Sets real-time search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filter by category pill (null = All)
  void setCategoryFilter(EntryCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Add new entry and encrypt immediately
  Future<bool> addEntry({
    required UserProfile profile,
    required String sessionPin,
    required VaultEntry entry,
  }) async {
    _entries.insert(0, entry);
    final saved = await _storageService.saveUserEntries(profile, sessionPin, _entries);
    if (saved) {
      await _storageService.updateEntryCount(profile, _entries.length);
      notifyListeners();
    }
    return saved;
  }

  /// Update entry and re-encrypt
  Future<bool> updateEntry({
    required UserProfile profile,
    required String sessionPin,
    required VaultEntry updatedEntry,
  }) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index == -1) return false;

    _entries[index] = updatedEntry;
    final saved = await _storageService.saveUserEntries(profile, sessionPin, _entries);
    if (saved) {
      notifyListeners();
    }
    return saved;
  }

  /// Delete entry and update storage
  Future<bool> deleteEntry({
    required UserProfile profile,
    required String sessionPin,
    required String entryId,
  }) async {
    _entries.removeWhere((e) => e.id == entryId);
    final saved = await _storageService.saveUserEntries(profile, sessionPin, _entries);
    if (saved) {
      await _storageService.updateEntryCount(profile, _entries.length);
      notifyListeners();
    }
    return saved;
  }

  /// Toggle favorite
  Future<void> toggleFavorite({
    required UserProfile profile,
    required String sessionPin,
    required String entryId,
  }) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;

    final entry = _entries[index];
    _entries[index] = entry.copyWith(isFavorite: !entry.isFavorite);
    await _storageService.saveUserEntries(profile, sessionPin, _entries);
    notifyListeners();
  }

  // --- Per-PIN / Sensitive Field Security Controls ---

  String _fieldKey(String entryId, String field) => '$entryId::$field';

  bool isFieldUnmasked(String entryId, String field) {
    return _unmaskedFields.contains(_fieldKey(entryId, field));
  }

  /// Unmasks sensitive field for 30 seconds with auto-hide protection
  void unmaskField(String entryId, String field, {int durationSeconds = 30}) {
    final key = _fieldKey(entryId, field);
    _unmaskedFields.add(key);

    // Cancel existing timer if present
    _unmaskTimers[key]?.cancel();

    // Set auto-hide timer
    _unmaskTimers[key] = Timer(Duration(seconds: durationSeconds), () {
      maskField(entryId, field);
    });

    notifyListeners();
  }

  /// Re-masks sensitive field immediately
  void maskField(String entryId, String field) {
    final key = _fieldKey(entryId, field);
    _unmaskedFields.remove(key);
    _unmaskTimers[key]?.cancel();
    _unmaskTimers.remove(key);
    notifyListeners();
  }

  /// Complete memory flush - guaranteed zero cross-contamination
  void clear() {
    _entries.clear();
    _searchQuery = '';
    _selectedCategory = null;
    for (final timer in _unmaskTimers.values) {
      timer.cancel();
    }
    _unmaskTimers.clear();
    _unmaskedFields.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _unmaskTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
