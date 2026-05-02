// lib/widgets/dialog_widgets/totp_setup_dialog.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:roadfix/services/totp_service.dart';
import 'package:roadfix/services/user_service.dart';
import 'package:roadfix/utils/responsive.dart';
import 'package:roadfix/widgets/themes.dart';

class TotpSetupDialog extends StatefulWidget {
  const TotpSetupDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TotpSetupDialog(),
    );
  }

  @override
  State<TotpSetupDialog> createState() => _TotpSetupDialogState();
}

class _TotpSetupDialogState extends State<TotpSetupDialog> {
  final UserService _userService = UserService();
  final TextEditingController _codeController = TextEditingController();

  late String _secret;
  late String _qrCodeUrl;

  bool _isLoading = true;
  bool _isVerifying = false;
  String? _errorMessage;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _generateTotpSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateTotpSetup() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) throw Exception('User not found');

      _secret = TotpService.generateSecret();

      _qrCodeUrl = TotpService.generateTotpUrl(
        secret: _secret,
        accountName: user.email,
        issuer: 'RoadFix',
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate TOTP setup: $e';
      });
    }
  }

  Future<void> _verifyAndEnable() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim();
      final isValid = TotpService.verifyCode(_secret, code);

      if (!isValid) {
        setState(() {
          _errorMessage = 'Invalid code. Please try again.';
          _isVerifying = false;
        });
        return;
      }

      final user = await _userService.getCurrentUser();
      if (user?.uid == null) throw Exception('User not found');

      // ✅ OFFLINE FIX: update via UserService (NOT Firestore)
      await _userService.enableTotp(user!.uid!, _secret);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to enable TOTP: $e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: inputFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(24.w),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_errorMessage!, style: const TextStyle(color: statusDanger)),
        const SizedBox(height: 16),
        TextButton(onPressed: _generateTotpSetup, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [if (_currentStep == 0) _buildQrStep() else _buildVerifyStep()],
    );
  }

  Widget _buildQrStep() {
    return Column(
      children: [
        QrImageView(data: _qrCodeUrl, size: 180),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text("Next"),
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: "000000",
            errorText: _errorMessage,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyAndEnable,
          child: const Text("Enable 2FA"),
        ),
      ],
    );
  }
}
