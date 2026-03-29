import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:user_app/login.dart';
import 'package:user_app/main.dart';
import 'package:user_app/theme.dart';

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
  file_picker.PlatformFile? pickedImage;

  /// 🔥 IMAGE PICKER
  Future<void> handleImagePick() async {
    final result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;

    setState(() {});
  }

  /// 🔥 UPLOAD IMAGE
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'User';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  /// 🔥 REGISTER FUNCTION
  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        contact.isEmpty ||
        password.isEmpty ||
        address.isEmpty) {
      showSnack("Please fill all fields");
      return;
    }

    if (pickedImage == null) {
      showSnack("Upload profile image");
      return;
    }

    if (password.length < 6) {
      showSnack("Password must be at least 6 characters");
      return;
    }

    try {
      setState(() => isLoading = true);

      /// 🔥 AUTH SIGNUP
      final auth = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (auth.user == null) throw Exception("Signup failed");

      final uid = auth.user!.id;

      /// 🔥 IMAGE UPLOAD
      final imageUrl = await photoUpload(uid);

      /// 🔥 INSERT USER DATA
      await supabase.from("tbl_user").insert({
        "id": uid,
        "user_name": name,
        "user_email": email,
        "user_contact": contact,
        "user_password": password,
        "user_photo": imageUrl,
        "user_address": address,
      });

      if (!mounted) return;

      showSnack("Registration successful");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    } catch (e) {
      showSnack(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    addressController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// 🔥 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Register to continue",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),

                  const SizedBox(height: 32),

                  /// CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// ICON
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.person_add,
                              color: AppTheme.primary, size: 30),
                        ),

                        const SizedBox(height: 24),

                        /// NAME
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter name" : null,
                        ),

                        const SizedBox(height: 16),

                        /// EMAIL
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter email" : null,
                        ),

                        const SizedBox(height: 16),

                        /// CONTACT
                        TextFormField(
                          controller: contactController,
                          decoration: const InputDecoration(
                            labelText: "Contact",
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter contact" : null,
                        ),

                        const SizedBox(height: 16),

                        /// ADDRESS
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: "Address",
                            prefixIcon:
                                Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter address" : null,
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        TextFormField(
                          controller: passwordController,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword),
                            ),
                          ),
                          validator: (v) => v!.length < 6
                              ? "Min 6 characters"
                              : null,
                        ),

                        const SizedBox(height: 16),

                        /// IMAGE
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: handleImagePick,
                            icon: const Icon(Icons.upload),
                            label: Text(
                              pickedImage == null
                                  ? "Upload Profile Image"
                                  : "Image Selected",
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!
                                        .validate()) {
                                      register();
                                    }
                                  },
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Register"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// LOGIN REDIRECT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const Login()),
                          );
                        },
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}