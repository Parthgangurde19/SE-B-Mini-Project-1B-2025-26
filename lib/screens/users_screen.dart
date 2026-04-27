import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading users:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No users found.', style: TextStyle(color: Color(0xFFF5E6D3))),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final name = data['name'] as String? ?? 'Unknown';
            final email = data['email'] as String? ?? '';
            final role = data['role'] as String? ?? 'customer';

            return _UserCard(
              key: ValueKey(uid),
              uid: uid,
              name: name,
              email: email,
              role: role,
            );
          },
        );
      },
    );
  }
}

class _UserCard extends StatefulWidget {
  final String uid;
  final String name;
  final String email;
  final String role;

  const _UserCard({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  late String _selectedRole;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void didUpdateWidget(covariant _UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.role != oldWidget.role && !_saving) {
      _selectedRole = widget.role;
    }
  }

  Future<void> _updateRole(String newRole) async {
    if (newRole == _selectedRole) return;
    setState(() {
      _selectedRole = newRole;
      _saving = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.name}\'s role updated to $newRole'),
            backgroundColor: const Color(0xFF4E342E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _selectedRole = widget.role);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User', style: TextStyle(color: Color(0xFFF5E6D3))),
        content: Text(
          'Are you sure you want to delete ${widget.name}? This will remove their profile from the database.',
          style: const TextStyle(color: Color(0xFFF5E6D3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFD4A574))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.name} has been deleted'),
            backgroundColor: const Color(0xFF4E342E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'admin';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isAdmin ? const Color(0xFFD4A574).withAlpha(60) : const Color(0xFF5C4033),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                color: isAdmin ? const Color(0xFFD4A574) : const Color(0xFFF5E6D3),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Name & email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Color(0xFFF5E6D3),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.email,
                    style: const TextStyle(color: Color(0xFFD4A574), fontSize: 12),
                  ),
                ],
              ),
            ),

            // Role dropdown
            if (_saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4A574)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C1A12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5C4033)),
                ),
                child: DropdownButton<String>(
                  value: _selectedRole,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2C1A12),
                  style: const TextStyle(color: Color(0xFFF5E6D3), fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    if (v != null) _updateRole(v);
                  },
                ),
              ),

            const SizedBox(width: 8),

            // Delete icon button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Delete User',
              onPressed: _deleteUser,
            ),
          ],
        ),
      ),
    );
  }
}
