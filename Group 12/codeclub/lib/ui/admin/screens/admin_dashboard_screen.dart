import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<AdminProvider>();
      await provider.loadDashboardStats();
      if (!mounted) return;
      await provider.loadAllHackathons();
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
            'CodeClub Admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await context.read<AdminProvider>().signOutAdmin();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            final stats = provider.dashStats;
            final adminName = provider.currentAdmin?.displayName ?? 'Admin';

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadDashboardStats();
                await provider.loadAllHackathons();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.8),
                          AppColors.primaryBlue.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, $adminName',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateTime.now().formattedDateTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Section Title
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StreamBuilder<int>(
                        stream: provider.totalUsersStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Total Users',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.primaryBlue,
                          value: '${snapshot.data ?? stats?.totalUsers ?? 0}',
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: provider.totalTeamsStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Total Teams',
                          icon: Icons.groups_rounded,
                          color: AppColors.secondaryGreen,
                          value: '${snapshot.data ?? stats?.totalTeams ?? 0}',
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: provider.activeHackathonsStream,
                        builder: (context, snapshot) => StatCard(
                          label: 'Active Hackathons',
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          value: '${snapshot.data ?? stats?.activeHackathons ?? 0}',
                        ),
                      ),
                      StatCard(
                        label: 'Total Hackathons',
                        icon: Icons.event_note_rounded,
                        color: AppColors.info,
                        value: '${stats?.totalHackathons ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/admin/hackathons/create'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Hackathon'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/admin/hackathons'),
                          icon: const Icon(Icons.list_rounded),
                          label: const Text('View All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Hackathons Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Hackathons',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (provider.hackathons.isNotEmpty)
                        TextButton(
                          onPressed: () => context.push('/admin/hackathons'),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Recent Hackathons List
                  if (provider.hackathons.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hackathons created yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: provider.hackathons.take(5).map((hackathon) {
                        return _HackathonCard(hackathon: hackathon);
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/hackathons/create'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Hackathon'),
          elevation: 8,
        ),
      ),
    );
  }
}

class _HackathonCard extends StatelessWidget {
  final dynamic hackathon;

  const _HackathonCard({required this.hackathon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.event_rounded,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(
          hackathon.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          hackathon.startDate.formattedDate,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => context.push(
          '/admin/hackathons/detail',
          extra: hackathon,
        ),
      ),
    );
  }
}
