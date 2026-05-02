import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roadfix/widgets/auth_widgets/auth_name_row.dart';
import 'package:roadfix/layouts/auth_scaffold.dart';
import 'package:roadfix/widgets/auth_widgets/signup_top_content.dart';
import 'package:roadfix/widgets/auth_widgets/custom_textfield.dart';
import 'package:roadfix/widgets/common_widgets/big_button.dart';
import 'package:roadfix/widgets/auth_widgets/auth_redirect_button.dart';
import 'package:roadfix/screens/auth_screens/login_screen.dart';

import 'package:roadfix/utils/focus_helper.dart';
import 'package:roadfix/models/user_model.dart';
import 'package:roadfix/services/auth_service.dart';
import 'package:roadfix/utils/snackbar_utils.dart';
import 'package:roadfix/widgets/dialog_widgets/dialog_utils.dart';
import 'package:roadfix/utils/responsive.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final miController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();

  final fnameFocus = FocusNode();
  final lnameFocus = FocusNode();
  final miFocus = FocusNode();
  final emailFocus = FocusNode();
  final contactNumberFocus = FocusNode();
  final addressFocus = FocusNode();
  final passwordFocus = FocusNode();

  DateTime? _selectedDateOfBirth;

  final _authService = AuthService.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    miController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    addressController.dispose();
    passwordController.dispose();

    fnameFocus.dispose();
    lnameFocus.dispose();
    miFocus.dispose();
    emailFocus.dispose();
    contactNumberFocus.dispose();
    addressFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  String? _validateFields() {
    final fname = fnameController.text.trim();
    final lname = lnameController.text.trim();
    final mi = miController.text.trim();
    final email = emailController.text.trim();
    final contact = contactNumberController.text.trim();
    final address = addressController.text.trim();
    final password = passwordController.text;

    if (fname.isEmpty || fname.length < 2) {
      return 'Invalid first name';
    }

    if (lname.isEmpty || lname.length < 2) {
      return 'Invalid last name';
    }

    if (mi.isNotEmpty && mi.length != 1) {
      return 'Invalid middle initial';
    }

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Invalid email';
    }

    if (contact.isEmpty) {
      return 'Contact number required';
    }

    if (address.isEmpty || address.length < 10) {
      return 'Invalid address';
    }

    if (password.isEmpty || password.length < 6) {
      return 'Weak password';
    }

    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password must contain letters & numbers';
    }

    if (_selectedDateOfBirth == null) {
      return 'Select birth date';
    }

    final today = DateTime.now();

    final age =
        today.year -
        _selectedDateOfBirth!.year -
        ((today.month < _selectedDateOfBirth!.month ||
                (today.month == _selectedDateOfBirth!.month &&
                    today.day < _selectedDateOfBirth!.day))
            ? 1
            : 0);

    if (age < 13) {
      return 'Must be 13+';
    }

    final digits = contact.replaceAll(RegExp(r'\D'), '');

    final validMobile = digits.length == 11 && digits.startsWith('09');

    final validLandline = digits.length >= 7 && digits.length <= 8;

    if (!validMobile && !validLandline) {
      return 'Invalid phone number';
    }

    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 16),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleSignUp() async {
    final error = _validateFields();

    if (error != null) {
      SnackbarUtils.showError(context, error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = UserModel(
        fname: fnameController.text.trim(),
        lname: lnameController.text.trim(),
        mi: miController.text.trim().toUpperCase(),
        email: emailController.text.trim().toLowerCase(),
        contactNumber: contactNumberController.text.trim(),
        address: addressController.text.trim(),
      );

      final result = await _authService.signUp(
        email: userData.email,
        password: passwordController.text,
        userData: userData,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        SnackbarUtils.showError(context, result['message'].toString());
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    DialogUtils.showSuccess(
      context: context,
      title: 'Account Created!',
      message: 'Account created successfully.',
      onPressed: () {
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      topPadding: 25,
      topContent: const SignupTopContent(),
      children: [
        SizedBox(height: 16.h),

        NameRow(
          firstNameController: fnameController,
          middleInitialController: miController,
          lastNameController: lnameController,
          firstNameFocus: fnameFocus,
          middleInitialFocus: miFocus,
          lastNameFocus: lnameFocus,
          nextFocus: emailFocus,
        ),

        SizedBox(height: 10.h),

        CustomTextField(
          label: 'Email Address',
          icon: Icons.email_outlined,
          controller: emailController,
          focusNode: emailFocus,
          onNext: () {
            FocusHelper.next(context, contactNumberFocus);
          },
        ),

        SizedBox(height: 10.h),

        CustomTextField(
          label: 'Contact Number',
          icon: Icons.phone_outlined,
          controller: contactNumberController,
          focusNode: contactNumberFocus,
          onNext: () {
            FocusHelper.next(context, addressFocus);
          },
        ),

        SizedBox(height: 10.h),

        CustomTextField(
          label: 'Address',
          icon: Icons.home_outlined,
          controller: addressController,
          focusNode: addressFocus,
          onNext: () {
            FocusHelper.next(context, passwordFocus);
          },
        ),

        SizedBox(height: 10.h),

        GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedDateOfBirth == null
                  ? 'Date of Birth'
                  : DateFormat('MMMM dd, yyyy').format(_selectedDateOfBirth!),
            ),
          ),
        ),

        SizedBox(height: 10.h),

        CustomTextField(
          label: 'Password',
          obscureText: true,
          icon: Icons.lock_outline,
          controller: passwordController,
          focusNode: passwordFocus,
          textInputAction: TextInputAction.done,
          onNext: () {
            FocusHelper.next(context, null);
          },
        ),

        SizedBox(height: 24.h),

        BigButton(
          text: _isLoading ? 'Creating...' : 'Sign Up',
          onPressed: _isLoading ? null : _handleSignUp,
        ),

        SizedBox(height: 16.h),

        AuthRedirectTextButton(
          prompt: 'Already have an account?',
          action: 'Sign In',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }
}
