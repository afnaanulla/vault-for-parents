import 'dart:convert';
import 'package:flutter/material.dart';

enum EntryCategory {
  bankAccount,
  card,
  upiPin,
  aadhaar,
  pan,
  secureNote,
}

extension EntryCategoryExt on EntryCategory {
  String get displayName {
    switch (this) {
      case EntryCategory.bankAccount:
        return 'Bank Account';
      case EntryCategory.card:
        return 'Debit / Credit Card';
      case EntryCategory.upiPin:
        return 'UPI / NetBanking';
      case EntryCategory.aadhaar:
        return 'Aadhaar Card';
      case EntryCategory.pan:
        return 'PAN Card';
      case EntryCategory.secureNote:
        return 'Secure Note';
    }
  }

  IconData get icon {
    switch (this) {
      case EntryCategory.bankAccount:
        return Icons.account_balance_rounded;
      case EntryCategory.card:
        return Icons.credit_card_rounded;
      case EntryCategory.upiPin:
        return Icons.pin_rounded;
      case EntryCategory.aadhaar:
        return Icons.badge_rounded;
      case EntryCategory.pan:
        return Icons.featured_play_list_rounded;
      case EntryCategory.secureNote:
        return Icons.lock_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EntryCategory.bankAccount:
        return const Color(0xFF2563EB); // Blue
      case EntryCategory.card:
        return const Color(0xFF0D9488); // Teal
      case EntryCategory.upiPin:
        return const Color(0xFF7C3AED); // Purple
      case EntryCategory.aadhaar:
        return const Color(0xFFEA580C); // Orange
      case EntryCategory.pan:
        return const Color(0xFF0284C7); // Sky Blue
      case EntryCategory.secureNote:
        return const Color(0xFF475569); // Slate
    }
  }
}

class VaultEntry {
  final String id;
  final EntryCategory category;
  final String title;
  final String institution;
  final Map<String, String> fields; // e.g. {'account_number': '...', 'ifsc': '...', 'pin': '...'}
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.institution,
    required this.fields,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  VaultEntry copyWith({
    String? id,
    EntryCategory? category,
    String? title,
    String? institution,
    Map<String, String>? fields,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      institution: institution ?? this.institution,
      fields: fields ?? this.fields,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'institution': institution,
      'fields': fields,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaultEntry.fromMap(Map<String, dynamic> map) {
    return VaultEntry(
      id: map['id'] as String,
      category: EntryCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String),
        orElse: () => EntryCategory.bankAccount,
      ),
      title: map['title'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      fields: Map<String, String>.from(map['fields'] as Map? ?? {}),
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory VaultEntry.fromJson(String source) =>
      VaultEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Checks if entry matches search query efficiently (case-insensitive)
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();

    if (title.toLowerCase().contains(q)) return true;
    if (institution.toLowerCase().contains(q)) return true;
    if (category.displayName.toLowerCase().contains(q)) return true;

    // Search within field values (e.g. last 4 digits of card or account number)
    for (final value in fields.values) {
      if (value.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
