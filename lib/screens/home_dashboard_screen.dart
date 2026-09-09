import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/user_profile.dart';
import '../models/vault_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/entries_provider.dart';
import '../widgets/vault_entry_card.dart';
import 'add_edit_entry_screen.dart';
import 'auth_screen.dart';
import 'user_selection_screen.dart';
import 'view_entry_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _lockVault() {
    final auth = context.read<AuthProvider>();
    final entries = context.read<EntriesProvider>();
    entries.clear();
    auth.lockVault();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _switchUser() {
    final auth = context.read<AuthProvider>();
    final entries = context.read<EntriesProvider>();
    entries.clear();
    auth.switchUser();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
      (route) => false,
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textBody,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final entriesProvider = context.watch<EntriesProvider>();
    final user = auth.currentUser ?? UserProfile.father;
    final accent = user.primaryColor;
    final filtered = entriesProvider.filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar & Profile Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Row
                    Row(
                      children: [
                        // User Avatar & Name
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: user.badgeBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user.avatarEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user.displayName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Data 100% Isolated & Encrypted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Switch User Button
                        IconButton(
                          icon: const Icon(Icons.people_outline_rounded),
                          tooltip: 'Switch Profile',
                          color: AppColors.textBody,
                          onPressed: _switchUser,
                        ),
                        // Quick Lock Button
                        IconButton(
                          icon: const Icon(Icons.lock_outline_rounded),
                          tooltip: 'Lock Vault',
                          color: AppColors.danger,
                          onPressed: _lockVault,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => entriesProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search by bank, card, or account...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  entriesProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Horizontal Category Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryPill(
                            label: 'All (${entriesProvider.totalCount})',
                            icon: Icons.grid_view_rounded,
                            isSelected: entriesProvider.selectedCategory == null,
                            activeColor: accent,
                            onTap: () => entriesProvider.setCategoryFilter(null),
                          ),
                          ...EntryCategory.values.map((cat) {
                            final count = entriesProvider.entries
                                .where((e) => e.category == cat)
                                .length;
                            return _buildCategoryPill(
                              label: '${cat.displayName} ($count)',
                              icon: cat.icon,
                              isSelected: entriesProvider.selectedCategory == cat,
                              activeColor: cat.color,
                              onTap: () => entriesProvider.setCategoryFilter(cat),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entriesProvider.selectedCategory?.displayName ?? 'All Vault Items',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${filtered.length} ${filtered.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Entries List
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _searchController.text.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.account_balance_wallet_outlined,
                            size: 40,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No matching entries found'
                              : 'Your vault is currently empty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try searching with another keyword or clear filter'
                              : 'Tap the button below to store your first bank account, card, or PIN safely.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              minimumSize: const Size(180, 48),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditEntryScreen(
                                    initialCategory: entriesProvider.selectedCategory,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Entry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VaultEntryCard(
                          entry: entry,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ViewEntryScreen(entry: entry),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Add Entry',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditEntryScreen(
                initialCategory: entriesProvider.selectedCategory,
              ),
            ),
          );
        },
      ),
    );
  }
}
