import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import 'chat_screen.dart';

/// Screen to create a new group chat
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final UserService _userService = UserService();

  List<UserModel> _searchResults = [];
  final List<UserModel> _selectedMembers = [];
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUserId = context.read<AuthProvider>().currentUserId;
      final results = await _userService.searchUsers(query: query);

      // Filter out current user and already selected members
      final filteredResults = results.where((user) {
        return user.uid != currentUserId &&
            !_selectedMembers.any((m) => m.uid == user.uid);
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _addMember(UserModel user) {
    setState(() {
      _selectedMembers.add(user);
      _searchResults.removeWhere((u) => u.uid == user.uid);
      _searchController.clear();
    });
  }

  void _removeMember(UserModel user) {
    setState(() {
      _selectedMembers.removeWhere((m) => m.uid == user.uid);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one member'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final userId = authProvider.currentUserId;

    if (userId == null) {
      setState(() => _isCreating = false);
      return;
    }

    final memberIds = _selectedMembers.map((m) => m.uid).toList();

    final chat = await chatProvider.createGroupChat(
      groupName: _nameController.text.trim(),
      creatorId: userId,
      memberIds: memberIds,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    setState(() => _isCreating = false);

    if (chat != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to the new group chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            title: chat.groupName ?? 'Group',
            isGroupChat: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage ?? 'Failed to create group'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Info Section
              Text(
                'Group Info',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Group Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is this group about?',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Members Section
              Text(
                'Add Members',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Search Users
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Members',
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  _searchUsers(value);
                },
              ),
              const SizedBox(height: 8),

              // Selected Members
              if (_selectedMembers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected (${_selectedMembers.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers.map((member) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundImage: member.profileImageUrl != null
                          ? CachedNetworkImageProvider(member.profileImageUrl!)
                            : null,
                        child: member.profileImageUrl == null
                            ? Text(member.fullName.initials)
                            : null,
                      ),
                      label: Text(member.fullName),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeMember(member),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Search Results
              if (_searchResults.isNotEmpty) ...[
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _UserSearchTile(
                          user: user,
                          onAdd: () => _addMember(user),
                        )
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 300.ms);
                  },
                ),
              ],

              // Empty state for search
              if (_searchController.text.isNotEmpty &&
                  _searchResults.isEmpty &&
                  !_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No users found')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User search tile widget
class _UserSearchTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAdd;

  const _UserSearchTile({required this.user, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundImage: user.profileImageUrl != null
            ? CachedNetworkImageProvider(user.profileImageUrl!)
            : null,
        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        child: user.profileImageUrl == null
            ? Text(
                user.fullName.initials,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(
        user.fullName,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user.email,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.primaryBlue,
      ),
    );
  }
}
