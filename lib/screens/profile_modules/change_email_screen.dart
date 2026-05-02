import 'package:flutter/material.dart';
import 'package:roadfix/widgets/common_widgets/custom_text_field.dart';
import 'package:roadfix/widgets/common_widgets/big_button.dart';
import 'package:roadfix/services/auth_service.dart';
import 'package:roadfix/utils/snackbar_utils.dart';
import 'package:roadfix/widgets/themes.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  final _newEmailFocus = FocusNode();
  final _currentPasswordFocus = FocusNode();

  // FIXED: DO NOT use AuthService() unless your class has empty constructor
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _emailChanged = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newEmailFocus.dispose();
    _currentPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  bool _hasChanges() {
    return _newEmailController.text.isNotEmpty ||
        _currentPasswordController.text.isNotEmpty;
  }

  Future<void> _handleCancel() async {
    if (_hasChanges() && !_emailChanged) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (shouldCancel == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context, _emailChanged);
    }
  }

  Future<void> _handleChangeEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final error = await _authService.changeEmail(
        newEmail: _newEmailController.text.trim(),
        currentPassword: _currentPasswordController.text,
      );

      if (!mounted) return;

      if (error != null) {
        SnackbarUtils.showError(context, error);
      } else {
        setState(() => _emailChanged = true);
        SnackbarUtils.showSuccess(context, 'Verification email sent!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to change email');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBack() {
    Navigator.pop(context, _emailChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    const Icon(Icons.email_outlined, size: 50, color: primary),

                    const SizedBox(height: 20),

                    const Text(
                      'Change Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    CustomTextField(
                      label: 'New Email Address',
                      controller: _newEmailController,
                      focusNode: _newEmailFocus,
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Current Password',
                      controller: _currentPasswordController,
                      focusNode: _currentPasswordFocus,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      onSuffixIconTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    BigButton(
                      text: _isLoading
                          ? "Sending..."
                          : "Send Verification Email",
                      onPressed: _isLoading ? null : _handleChangeEmail,
                    ),

                    const SizedBox(height: 10),

                    if (!_emailChanged)
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleCancel,
                        child: const Text("Cancel"),
                      )
                    else
                      BigButton(text: "Done", onPressed: _goBack),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
