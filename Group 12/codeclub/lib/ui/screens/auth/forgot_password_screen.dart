import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';

/// Forgot password screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send reset email'),
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
            child: _emailSent ? _buildSuccessContent() : _buildFormContent(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 32),
          // Header
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
          const SizedBox(height: 12),
          Text(
            "No worries! Enter your email address and we'll send you a link to reset your password.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 40),
          // Email field
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your.email@apsit.edu.in',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: Validators.validateEmail,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleResetPassword(),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 500.ms,
              ),
          const SizedBox(height: 32),
          // Reset button
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PrimaryButton(
                text: 'Send Reset Link',
                isLoading: auth.isLoading,
                onPressed: _handleResetPassword,
                width: double.infinity,
              );
            },
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 500.ms,
              ),
          const SizedBox(height: 24),
          // Back to login
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Sign In'),
          ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // Success icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 50,
              color: AppColors.success,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 32),
        // Success message
        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 24),
        Text(
          'Please check your inbox and follow the instructions to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
        const SizedBox(height: 40),
        // Back to login button
        PrimaryButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
          width: double.infinity,
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
        const SizedBox(height: 16),
        // Resend link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text("Didn't receive the email? Try again"),
        ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
      ],
    );
  }
}
