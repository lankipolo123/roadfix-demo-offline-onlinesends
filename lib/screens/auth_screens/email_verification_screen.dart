// lib/screens/auth_screens/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:roadfix/services/auth_service.dart';
import 'package:roadfix/utils/snackbar_utils.dart';
import 'package:roadfix/widgets/common_widgets/big_button.dart';
import 'package:roadfix/layouts/auth_scaffold.dart';
import 'package:roadfix/widgets/auth_widgets/auth_redirect_button.dart';
import 'package:roadfix/screens/module_screens/navigation_screen.dart';
import 'package:roadfix/screens/auth_screens/login_screen.dart';
import 'package:roadfix/widgets/themes.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService.instance;

  bool _isCheckingVerification = false;
  bool _isResendingEmail = false;

  // ✅ FIXED: Map access instead of .email
  String get userEmail => _authService.currentUser?['email'] ?? 'your email';

  Future<void> _checkEmailVerification() async {
    setState(() => _isCheckingVerification = true);

    try {
      final error = await _authService.checkEmailVerificationAndActivate();

      if (!mounted) return;

      if (error == null) {
        SnackbarUtils.showSuccess(context, 'Email verified successfully! 🎉');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavigationScreen()),
        );
      } else {
        SnackbarUtils.showError(context, error);
      }
    } catch (_) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to check verification status');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResendingEmail = true);

    try {
      final error = await _authService.resendEmailVerification();

      if (!mounted) return;

      if (error == null) {
        SnackbarUtils.showSuccess(context, 'Verification email sent!');
      } else {
        SnackbarUtils.showError(context, error);
      }
    } catch (_) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to resend verification email');
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingEmail = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (_) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to sign out');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      topPadding: 30,
      topContent: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email_outlined, size: 64, color: primary),
          ),

          const SizedBox(height: 24),

          const Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: secondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          const Text(
            'We sent a verification link to',
            style: TextStyle(color: altSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            userEmail,
            style: const TextStyle(fontWeight: FontWeight.w600, color: primary),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Check your email and click the verification link before continuing.',
              style: TextStyle(color: secondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 24),

        BigButton(
          text: _isCheckingVerification
              ? "Checking..."
              : "I've Verified My Email",
          onPressed: _isCheckingVerification ? null : _checkEmailVerification,
        ),

        const SizedBox(height: 16),

        OutlinedButton(
          onPressed: _isResendingEmail ? null : _resendVerificationEmail,
          child: Text(
            _isResendingEmail ? "Sending..." : "Resend Verification Email",
          ),
        ),

        const SizedBox(height: 24),

        AuthRedirectTextButton(
          prompt: "Wrong account?",
          action: "Sign Out",
          onPressed: _signOut,
        ),
      ],
    );
  }
}
