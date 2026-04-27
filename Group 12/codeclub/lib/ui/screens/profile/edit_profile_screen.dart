import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';

/// Edit profile screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _linkedInController;
  late TextEditingController _githubController;
  
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedRole;
  List<String> _selectedSkills = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _linkedInController = TextEditingController(text: user?.linkedInUrl ?? '');
    _githubController = TextEditingController(text: user?.githubUrl ?? '');
    _selectedBranch = user?.branch;
    _selectedYear = user?.year;
    _selectedRole = user?.role;
    _selectedSkills = List.from(user?.skills ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      fullName: _nameController.text.trim(),
      branch: _selectedBranch ?? '',
      year: _selectedYear ?? '',
      role: _selectedRole ?? '',
      skills: _selectedSkills,
      bio: _bioController.text.trim(),
      linkedInUrl: _linkedInController.text.trim().isEmpty ? null : _linkedInController.text.trim(),
      githubUrl: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await authProvider.updateProfile(updatedUser);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.profileSaved),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return TextButton(
                onPressed: auth.isLoading ? null : _handleSave,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full name
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 20),
              // Branch dropdown
              Text(
                'Branch',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: const InputDecoration(
                  hintText: 'Select your branch',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: Branches.branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch,
                    child: Text(branch),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBranch = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Year dropdown
              Text(
                'Year',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  hintText: 'Select your year',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: AcademicYears.years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Role selection
              Text(
                'Preferred Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StudentRoles.roles.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRole = selected ? role : null;
                      });
                    },
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Skills selection
              Text(
                'Skills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CommonSkills.skills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Bio
              CustomTextField(
                controller: _bioController,
                label: 'Short Bio',
                hint: 'Tell others about yourself...',
                maxLines: 4,
                maxLength: 200,
                validator: Validators.validateBio,
              ),
              const SizedBox(height: 24),
              // Social links section
              Text(
                'Social Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your LinkedIn and GitHub profiles (optional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 16),
              // LinkedIn URL
              CustomTextField(
                controller: _linkedInController,
                label: 'LinkedIn Profile (Optional)',
                hint: 'https://linkedin.com/in/yourprofile',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.link_outlined),
              ),
              const SizedBox(height: 20),
              // GitHub URL
              CustomTextField(
                controller: _githubController,
                label: 'GitHub Profile (Optional)',
                hint: 'https://github.com/yourusername',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.link_outlined),
              ),
              const SizedBox(height: 32),
              // Save button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return PrimaryButton(
                    text: 'Save Changes',
                    isLoading: auth.isLoading,
                    onPressed: _handleSave,
                    width: double.infinity,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
