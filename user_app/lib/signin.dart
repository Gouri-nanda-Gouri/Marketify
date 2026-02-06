import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:user_app/login.dart';
import 'package:user_app/main.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();

  bool _hidePassword = true;
  bool isLoading = false;

  Uint8List? imageBytes;
  PlatformFile? pickedImage;

  /// IMAGE PICKER (FIXED)
  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.image,
      withData: true, // IMPORTANT
    );

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;

    debugPrint("✅ Image picked: ${imageBytes!.length} bytes");
    setState(() {});
  }

  /// PHOTO UPLOAD
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'User';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      return null;
    }
  }

 Future<void> register() async {
  try {
    final name = nameController.text;
    final email = emailController.text;
    final contact = contactController.text;
    final password = passwordController.text;
    final address = addressController.text;
    
    // Input validation
    if (name.isEmpty ||
        email.isEmpty ||
        contact.isEmpty ||
        password.isEmpty ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all the fields")));
      return;
    }
    
    if (pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload your profile image")));
      return;
    }
    
    
    
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Password must be at least 6 characters long")));
      return;
    }

    // Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Sign up with Supabase auth
    final auth = await supabase.auth.signUp(
    password: passwordController.text.trim(),
    email: emailController.text.trim(),
  );

  if (auth.user == null) throw Exception("User creation failed");
  String uid = auth.user!.id;

  // 3. Upload photo
  String? profileImageUrl = await photoUpload(uid);

  // 4. Insert data
  await supabase.from("tbl_user").insert({
    "id": uid,
    "user_name": nameController.text,
    "user_email": emailController.text,
    "user_contact": contactController.text,
    "user_password": passwordController.text, // Note: Storing plain text passwords is risky!
    "user_photo": profileImageUrl,
    "user_address": addressController.text,
  });
  print("User registered with ID: $uid");

  // 5. SAFE CONTEXT CHECK
  if (!mounted) return;
  setState(() => isLoading = false);

  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration successful!")));
  
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (context) => const Login()),
  );
  
} catch (error) { // Use 'error' instead of 'e'
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop(); // This closes the loading spinner so you can see the screen
  }
  
  print("ACTUAL ERROR: $error");
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      backgroundColor: Colors.red,
    ),
  );
}
 }
   


  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// IMAGE PREVIEW
                      GestureDetector(
                        onTap: handleImagePick,
                        child: Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.grey.shade200,
                          ),
                          child: imageBytes == null
                              ? const Icon(Icons.person, size: 40)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.memory(
                                    imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _field(nameController, "Name", Icons.person),
                      _field(emailController, "Email", Icons.email),
                      _field(contactController, "Contact", Icons.phone),
                      _field(addressController, "Address", Icons.location_on),
                      _passwordField(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _hidePassword,
      validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
              Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () =>
              setState(() => _hidePassword = !_hidePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
