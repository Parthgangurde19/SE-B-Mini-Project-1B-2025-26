import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';

/// Profile setup screen for first-time users
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedRole;
  List<String> _selectedSkills = [];
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found. Please try logging in again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final updatedUser = currentUser.copyWith(
        fullName: _nameController.text.trim(),
        branch: _selectedBranch ?? '',
        year: _selectedYear ?? '',
        role: _selectedRole ?? '',
        skills: _selectedSkills,
        bio: _bioController.text.trim(),
        linkedInUrl: _linkedInController.text.trim().isEmpty ? null : _linkedInController.text.trim(),
        githubUrl: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
        isProfileComplete: true,
        updatedAt: DateTime.now(),
      );

      final success = await authProvider.updateProfile(updatedUser);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.profileSaved),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate to home using GoRouter
        context.go('/home');
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to save profile'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _handleSaveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _selectedBranch != null &&
            _selectedYear != null;
      case 1:
        return _selectedRole != null && _selectedSkills.isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryBlue
                                    : (isDark ? AppColors.cardDark : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (index < 2) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(),
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: PrimaryButton(
                          text: 'Back',
                          isOutlined: true,
                          onPressed: _previousStep,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 2,
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return PrimaryButton(
                            text: _currentStep < 2 ? 'Continue' : 'Complete Setup',
                            isLoading: auth.isLoading,
                            onPressed: _canProceed() ? _nextStep : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildSkillsStep();
      case 2:
        return _buildBioStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'Tell us a bit about yourself',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 32),
        // Full name
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: const Icon(Icons.person_outline_rounded),
          validator: Validators.validateName,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
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
          validator: (value) => value == null ? 'Please select your branch' : null,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
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
          validator: (value) => value == null ? 'Please select your year' : null,
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
            ),
      ],
    );
  }

  Widget _buildSkillsStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills & Role',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'What do you bring to a team?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 32),
        // Role selection
        Text(
          'Preferred Role',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
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
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 32),
        // Skills selection
        Text(
          'Skills (Select at least 1)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
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
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_selectedSkills.length} skill(s) selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'Add a short bio (optional)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 32),
        // Bio
        CustomTextField(
          controller: _bioController,
          label: 'Short Bio',
          hint: 'Tell others about yourself, your interests, and what you\'re looking for in a team...',
          maxLines: 5,
          maxLength: 200,
          validator: Validators.validateBio,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
            ),
        const SizedBox(height: 24),
        // Social links section
        Text(
          'Social Links (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
        const SizedBox(height: 12),
        Text(
          'Add your LinkedIn and GitHub profiles to help teammates connect with you',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ).animate().fadeIn(delay: 275.ms, duration: 400.ms),
        const SizedBox(height: 16),
        // LinkedIn URL
        CustomTextField(
          controller: _linkedInController,
          label: 'LinkedIn Profile (Optional)',
          hint: 'https://linkedin.com/in/yourprofile',
          keyboardType: TextInputType.url,
          prefixIcon: const Icon(Icons.link_outlined),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
            ),
        const SizedBox(height: 20),
        // GitHub URL
        CustomTextField(
          controller: _githubController,
          label: 'GitHub Profile (Optional)',
          hint: 'https://github.com/yourusername',
          keyboardType: TextInputType.url,
          prefixIcon: const Icon(Icons.link_outlined),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
            ),
        const SizedBox(height: 24),
        // Preview card
        Text(
          'Profile Preview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 12),
        _buildProfilePreview().animate().fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildProfilePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _nameController.text.trim();
    final initials = name.isEmpty
        ? '?'
        : name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Your Name' : name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedRole ?? 'Role',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_selectedBranch ?? 'Branch'} • ${_selectedYear ?? 'Year'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (_selectedSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedSkills.take(5).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primaryBlue.withValues(alpha: 0.2)
                          : AppColors.primaryBlueLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
