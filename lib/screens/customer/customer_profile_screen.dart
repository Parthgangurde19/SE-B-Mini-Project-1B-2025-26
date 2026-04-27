import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loyalty_card_widget.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        // Avatar
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorScheme.primary, const Color(0xFF8B6F47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            user?.name ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            user?.email ?? '',
            style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.role.toUpperCase() ?? 'CUSTOMER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Loyalty Card
        const LoyaltyCardWidget(),
        const SizedBox(height: 28),

        // Profile fields
        _ProfileTile(icon: Icons.person_rounded, title: 'Full Name', subtitle: user?.name ?? ''),
        _ProfileTile(icon: Icons.email_rounded, title: 'Email', subtitle: user?.email ?? ''),
        _ProfileTile(
          icon: Icons.security_rounded,
          title: 'Role',
          subtitle: user?.role == 'admin' ? 'Administrator' : 'Customer',
        ),
        const SizedBox(height: 32),

        // Logout
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(120))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
