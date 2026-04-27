import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

/// Login screen with APSIT email validation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.08),
                  // Logo and title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            // Light background in dark mode, transparent in light mode
                            color: isDark ? Colors.grey[900] : Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              // For dark mode, ensure logo is visible
                              color: isDark ? null : null,
                              colorBlendMode: BlendMode.darken,
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms).scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 24),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appTagline,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.06),
                  // Login form
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideX(
                        begin: -0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your APSIT email',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  const SizedBox(height: 32),
                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'your.email@apsit.edu.in',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 20),
                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                  ).animate().fadeIn(delay: 700.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 12),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                  const SizedBox(height: 24),
                  // Login button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return PrimaryButton(
                        text: 'Sign In',
                        isLoading: auth.isLoading,
                        onPressed: _handleLogin,
                        width: double.infinity,
                      );
                    },
                  ).animate().fadeIn(delay: 900.ms, duration: 500.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 500.ms,
                      ),
                  const SizedBox(height: 32),
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
                  const SizedBox(height: 24),
                  // APSIT only notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Only APSIT students with @apsit.edu.in email can access this app.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.info,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
