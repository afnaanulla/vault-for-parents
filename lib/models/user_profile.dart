import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum UserType {
  father,
  mother,
}

class UserProfile {
  final UserType type;
  final String id;
  final String displayName;
  final String avatarEmoji;
  final Color primaryColor;
  final Color badgeBgColor;
  final String storagePrefix;

  const UserProfile({
    required this.type,
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    required this.primaryColor,
    required this.badgeBgColor,
    required this.storagePrefix,
  });

  static const UserProfile father = UserProfile(
    type: UserType.father,
    id: 'father',
    displayName: 'Father',
    avatarEmoji: '👨',
    primaryColor: AppColors.fatherPrimary,
    badgeBgColor: AppColors.fatherBg,
    storagePrefix: 'vault_father_',
  );

  static const UserProfile mother = UserProfile(
    type: UserType.mother,
    id: 'mother',
    displayName: 'Mother',
    avatarEmoji: '👩',
    primaryColor: AppColors.motherPrimary,
    badgeBgColor: AppColors.motherBg,
    storagePrefix: 'vault_mother_',
  );

  static List<UserProfile> get allProfiles => [father, mother];

  static UserProfile fromId(String id) {
    if (id == mother.id) return mother;
    return father;
  }
}
