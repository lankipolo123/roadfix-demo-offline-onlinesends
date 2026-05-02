// lib/screens/profile_modules/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roadfix/services/imagekit_services.dart';
import 'package:roadfix/services/user_service.dart';
import 'package:roadfix/models/user_model.dart';
import 'package:roadfix/widgets/common_widgets/user_avatar.dart';
import 'package:roadfix/widgets/dialog_widgets/image_source_dialog.dart';
import 'package:roadfix/widgets/themes.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _imageKitService = ImageKitService();
  final _imagePicker = ImagePicker();

  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  File? _selectedImageFile;
  bool _hasImageChanged = false;

  @override
  void dispose() {
    _contactNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: statusDanger),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: statusSuccess),
    );
  }

  Future<void> _pickImage() async {
    try {
      final source = await ImageSourceDialog.show(context);
      if (source == null) return;

      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _selectedImageFile = File(picked.path);
        _hasImageChanged = true;
      });
    } catch (e) {
      _showError("Image pick failed: $e");
    }
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = user.userProfile;

      if (_hasImageChanged && _selectedImageFile != null) {
        final response = await _imageKitService.uploadProfileImage(
          _selectedImageFile!,
        );

        finalImageUrl = response.fileUrl.split('?').first;
      }

      await _userService.updateProfile(
        contactNumber: _contactNumberController.text.trim(),
        address: _addressController.text.trim(),
        userProfile: finalImageUrl,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;

      _showSuccess("Profile updated!");
      Navigator.pop(context, true);
    } catch (e) {
      _showError("Update failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: StreamBuilder<UserModel?>(
        stream: _userService.getCurrentUserStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          // safe init (NO redundant null checks)
          _contactNumberController.text = _contactNumberController.text.isEmpty
              ? user.contactNumber
              : _contactNumberController.text;

          _addressController.text = _addressController.text.isEmpty
              ? user.address
              : _addressController.text;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 80, 30, 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    children: [
                      UserAvatar(
                        imageUrl: user.userProfile,
                        radius: 60,
                        lastUpdated: user.lastUpdated,
                        onTap: _pickImage,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(
                      labelText: "Contact Number",
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "Address"),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveProfile(user),
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text("Save Changes"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
