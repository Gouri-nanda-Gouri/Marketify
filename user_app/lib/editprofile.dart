import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'main.dart';

class EditProfile extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfile({super.key, required this.userData});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController nameController;
  late TextEditingController contactController;
  late TextEditingController addressController;

  Uint8List? imageBytes;
  PlatformFile? pickedImage;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.userData['user_name']);
    contactController =
        TextEditingController(text: widget.userData['user_contact']);
    addressController =
        TextEditingController(text: widget.userData['user_address']);
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;
    setState(() {});
  }

  Future<void> updateProfile() async {
    setState(() => isSaving = true);

    String? imageUrl = widget.userData['user_photo'];

    try {
      if (imageBytes != null) {
        final path =
            "profile/${widget.userData['id']}.${pickedImage!.extension}";
        await supabase.storage.from('User').uploadBinary(
              path,
              imageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = supabase.storage.from('User').getPublicUrl(path);
      }

      await supabase.from('tbl_user').update({
        'user_name': nameController.text.trim(),
        'user_contact': contactController.text.trim(),
        'user_address': addressController.text.trim(),
        'user_photo': imageUrl,
      }).eq('id', widget.userData['id']);

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Update error: $e");
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Profile Image =====
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppTheme.card,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes!)
                          : NetworkImage(widget.userData['user_photo'] ?? '')
                              as ImageProvider,
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickImage,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.background, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // ===== Form Card =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      label: "Name",
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    CustomTextField(
                      controller: contactController,
                      label: "Contact",
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    CustomTextField(
                      controller: addressController,
                      label: "Address",
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ===== Save Button =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: CustomButton(
                text: "Save Changes",
                isLoading: isSaving,
                onPressed: updateProfile,
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
