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

/// Signup screen with APSIT email validation
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please complete your profile.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to profile setup screen using GoRouter
      context.go('/profile-setup');
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 500.ms).slideX(
                        begin: -0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Join ${AppConstants.appName} to find your perfect hackathon team',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
                  SizedBox(height: size.height * 0.04),
                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'your.email@apsit.edu.in',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 20),
                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a strong password',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 20),
                  // Confirm password field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    textInputAction: TextInputAction.done,
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 24),
                  // Optional social links section
                  Text(
                    'Social Links (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Add your LinkedIn and GitHub profiles to help teammates find you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ).animate().fadeIn(delay: 475.ms, duration: 500.ms),
                  const SizedBox(height: 16),
                  // LinkedIn URL field
                  CustomTextField(
                    controller: _linkedInController,
                    label: 'LinkedIn Profile (Optional)',
                    hint: 'https://linkedin.com/in/yourprofile',
                    keyboardType: TextInputType.url,
                    prefixIcon: const Icon(Icons.link_outlined),
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 20),
                  // GitHub URL field
                  CustomTextField(
                    controller: _githubController,
                    label: 'GitHub Profile (Optional)',
                    hint: 'https://github.com/yourusername',
                    keyboardType: TextInputType.url,
                    prefixIcon: const Icon(Icons.link_outlined),
                    textInputAction: TextInputAction.done,
                  ).animate().fadeIn(delay: 550.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 24),
                  // Terms checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryBlue,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreeToTerms = !_agreeToTerms;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  const SizedBox(height: 32),
                  // Signup button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return PrimaryButton(
                        text: 'Create Account',
                        isLoading: auth.isLoading,
                        onPressed: _handleSignup,
                        width: double.infinity,
                      );
                    },
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 24),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                  const SizedBox(height: 24),
                  // Password requirements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _PasswordRequirement(
                          text: 'At least 6 characters',
                          isMet: _passwordController.text.length >= 6,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password requirement indicator
class _PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isMet;

  const _PasswordRequirement({
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: isMet ? AppColors.success : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isMet ? AppColors.success : null,
              ),
        ),
      ],
    );
  }
}
