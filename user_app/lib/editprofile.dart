import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    const primaryBlue = Color(0xFF2E6CF6);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Profile Image =====
            Container(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes!)
                          : NetworkImage(widget.userData['user_photo'])
                              as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickImage,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      color: Color(0x11000000),
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _inputField(
                      controller: nameController,
                      label: "Name",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: contactController,
                      label: "Contact",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: addressController,
                      label: "Address",
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ===== Save Button =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: isSaving ? null : updateProfile,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        color: primaryBlue.withOpacity(0.35),
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ===== Reusable Input =====
Widget _inputField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
