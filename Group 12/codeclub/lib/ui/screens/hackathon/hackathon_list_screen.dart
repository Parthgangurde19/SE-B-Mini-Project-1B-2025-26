import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/hackathon_provider.dart';
import '../../widgets/hackathon_card.dart';
import '../../widgets/loading_widgets.dart';
import 'hackathon_detail_screen.dart';

/// Hackathons listing screen
class HackathonListScreen extends StatefulWidget {
  const HackathonListScreen({super.key});

  @override
  State<HackathonListScreen> createState() => _HackathonListScreenState();
}

class _HackathonListScreenState extends State<HackathonListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHackathons();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHackathons() async {
    await context.read<HackathonProvider>().loadHackathons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hackathons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Applications',
            onPressed: () => context.push('/my-applications'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Consumer<HackathonProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const ShimmerList(itemCount: 4, itemHeight: 220);
          }

          if (provider.errorMessage != null) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: _loadHackathons,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _HackathonTabView(
                hackathons: provider.upcomingHackathons,
                emptyTitle: 'No upcoming hackathons',
                emptySubtitle: 'Check back later for new events',
              ),
              _HackathonTabView(
                hackathons: provider.ongoingHackathons,
                emptyTitle: 'No ongoing hackathons',
                emptySubtitle: 'No hackathons are currently in progress',
              ),
              _HackathonTabView(
                hackathons: provider.pastHackathons,
                emptyTitle: 'No past hackathons',
                emptySubtitle: 'Past events will appear here',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hackathon tab view
class _HackathonTabView extends StatelessWidget {
  final List<HackathonModel> hackathons;
  final String emptyTitle;
  final String emptySubtitle;

  const _HackathonTabView({
    required this.hackathons,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (hackathons.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.emoji_events_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<HackathonProvider>().loadHackathons();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hackathons.length,
        itemBuilder: (context, index) {
          final hackathon = hackathons[index];
          
          return HackathonCard(
            hackathon: hackathon,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HackathonDetailScreen(hackathon: hackathon),
                ),
              );
            },
          )
              .animate(delay: Duration(milliseconds: index * 100))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms);
        },
      ),
    );
  }
}
