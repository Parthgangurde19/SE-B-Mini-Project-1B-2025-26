import 'package:flutter/material.dart';
// Removed unused import: flutter_animate
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/text_fields.dart';
import '../../widgets/user_card.dart';
import 'user_detail_screen.dart';

/// Find team members screen
class FindMembersScreen extends StatefulWidget {
  const FindMembersScreen({super.key});

  @override
  State<FindMembersScreen> createState() => _FindMembersScreenState();
}

class _FindMembersScreenState extends State<FindMembersScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String? _selectedSkill;
  String? _selectedRole;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = context.read<AuthProvider>().currentUserId;
      _users = await _userService.getAllUsers(excludeUserId: currentUserId);
      _filteredUsers = _users;
    } catch (e) {
      _errorMessage = e.toString();
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          if (!user.fullName.toLowerCase().contains(query) &&
              !user.skills.any((s) => s.toLowerCase().contains(query))) {
            return false;
          }
        }

        // Skill filter
        if (_selectedSkill != null) {
          if (!user.skills.contains(_selectedSkill)) {
            return false;
          }
        }

        // Role filter
        if (_selectedRole != null) {
          if (user.role != _selectedRole) {
            return false;
          }
        }

        // Year filter
        if (_selectedYear != null) {
          if (user.year != _selectedYear) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSkill = null;
      _selectedRole = null;
      _selectedYear = null;
      _searchController.clear();
      _filteredUsers = _users;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedSkill: _selectedSkill,
        selectedRole: _selectedRole,
        selectedYear: _selectedYear,
        onApply: (skill, role, year) {
          setState(() {
            _selectedSkill = skill;
            _selectedRole = role;
            _selectedYear = year;
          });
          _filterUsers();
          Navigator.pop(context);
        },
        onClear: () {
          _clearFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        _selectedSkill != null ||
        _selectedRole != null ||
        _selectedYear != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Find Team Members')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Search by name or skill...',
              onChanged: (_) => _filterUsers(),
              onClear: _filterUsers,
              onFilterTap: _showFilterBottomSheet,
            ),
          ),
          // Active filters
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedSkill != null)
                            _FilterChip(
                              label: _selectedSkill!,
                              onRemove: () {
                                setState(() {
                                  _selectedSkill = null;
                                });
                                _filterUsers();
                              },
                            ),
                          if (_selectedRole != null)
                            _FilterChip(
                              label: _selectedRole!,
                              onRemove: () {
                                setState(() {
                                  _selectedRole = null;
                                });
                                _filterUsers();
                              },
                            ),
                          if (_selectedYear != null)
                            _FilterChip(
                              label: _selectedYear!,
                              onRemove: () {
                                setState(() {
                                  _selectedYear = null;
                                });
                                _filterUsers();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredUsers.length} member(s) found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const ShimmerList(itemCount: 5, itemHeight: 150)
                : _errorMessage != null
                ? ErrorStateWidget(message: _errorMessage!, onRetry: _loadUsers)
                : _filteredUsers.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.person_search_rounded,
                    title: 'No members found',
                    subtitle: 'Try adjusting your filters or search query',
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return UserProfileCard(
                          user: user,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetailScreen(user: user),
                              ),
                            );
                          },
                          onMessageTap: () {
                            // TODO: Navigate to chat
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedSkill;
  final String? selectedRole;
  final String? selectedYear;
  final Function(String?, String?, String?) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    this.selectedSkill,
    this.selectedRole,
    this.selectedYear,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _skill;
  late String? _role;
  late String? _year;

  @override
  void initState() {
    super.initState();
    _skill = widget.selectedSkill;
    _role = widget.selectedRole;
    _year = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Members',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClear,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Filters
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role filter
                    Text(
                      'Role',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StudentRoles.roles.map((role) {
                        final isSelected = _role == role;
                        return ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _role = selected ? role : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Year filter
                    Text(
                      'Year',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AcademicYears.years.map((year) {
                        final isSelected = _year == year;
                        return ChoiceChip(
                          label: Text(year),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _year = selected ? year : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Skill filter
                    Text(
                      'Skill',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CommonSkills.skills.map((skill) {
                        final isSelected = _skill == skill;
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _skill = selected ? skill : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_skill, _role, _year),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
