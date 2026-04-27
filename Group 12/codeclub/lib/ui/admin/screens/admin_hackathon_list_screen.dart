import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/hackathon_admin_tile.dart';

class AdminHackathonListScreen extends StatefulWidget {
  const AdminHackathonListScreen({super.key});

  @override
  State<AdminHackathonListScreen> createState() => _AdminHackathonListScreenState();
}

class _AdminHackathonListScreenState extends State<AdminHackathonListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAllHackathons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AdminAuthGuard(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Manage Hackathons',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final list = provider.filteredHackathons;

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by title or venue',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                
                // Filter Chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: provider.filterStatus == null,
                        onTap: () => provider.setFilter(null),
                      ),
                      ...HackathonStatus.values.map(
                        (status) => _FilterChip(
                          label: status.label,
                          selected: provider.filterStatus == status,
                          onTap: () => provider.setFilter(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // List or Empty State
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => provider.loadAllHackathons(),
                          child: list.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height: 280,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.emoji_events_outlined,
                                              size: 56,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No hackathons found',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Create a new hackathon to get started',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[500],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final hackathon = list[index];
                                    return Dismissible(
                                      key: ValueKey(hackathon.id),
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 20),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      direction: DismissDirection.startToEnd,
                                      confirmDismiss: (_) => _confirmDelete(
                                        context,
                                        hackathon,
                                      ),
                                      onDismissed: (_) async {
                                        await provider.deleteHackathon(hackathon.id);
                                      },
                                      child: HackathonAdminTile(
                                        hackathon: hackathon,
                                        onTap: () => context.push(
                                          '/admin/hackathons/detail',
                                          extra: hackathon,
                                        ),
                                        onEdit: () => context.push(
                                          '/admin/hackathons/edit',
                                          extra: hackathon,
                                        ),
                                        onDelete: () async {
                                          final confirmed = await _confirmDelete(
                                            context,
                                            hackathon,
                                          );
                                          if (confirmed == true && context.mounted) {
                                            await context
                                                .read<AdminProvider>()
                                                .deleteHackathon(hackathon.id);
                                          }
                                        },
                                        onStatusChange: (status) async {
                                          await context
                                              .read<AdminProvider>()
                                              .toggleStatus(hackathon.id, status);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/hackathons/create'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Hackathon'),
          elevation: 8,
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, HackathonModel hackathon) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hackathon?'),
        content: Text(
          "This will hide '${hackathon.title}' from students. Registered teams will not be affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : null,
          ),
        ),
        selected: selected,
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primaryBlue,
        side: BorderSide(
          color: selected
              ? AppColors.primaryBlue
              : Colors.grey[300]!,
          width: selected ? 0 : 1,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
