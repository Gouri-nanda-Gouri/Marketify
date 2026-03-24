import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'main.dart';

class ChangePassword extends StatefulWidget {
  final String userId;
  const ChangePassword({super.key, required this.userId});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final oldPass = TextEditingController();
  final newPass = TextEditingController();

  bool isLoading = false;
  bool showOld = false;
  bool showNew = false;

  Future<void> updatePassword() async {
    if (oldPass.text.isEmpty || newPass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required"), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await supabase
          .from('tbl_user')
          .select()
          .eq('id', widget.userId)
          .single();

      if (user['user_password'] != oldPass.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Old password incorrect"), backgroundColor: AppTheme.error),
        );
        setState(() => isLoading = false);
        return;
      }

      await supabase.from('tbl_user').update({
        'user_password': newPass.text.trim(),
      }).eq('id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully"), backgroundColor: AppTheme.success),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Password update error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "Change Password"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ===== Icon =====
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_outlined,
                size: 56,
                color: AppTheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Update your password",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Choose a strong password for better security",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 32),

            // ===== Form Card =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: CustomCard(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: oldPass,
                      label: "Old Password",
                      isPassword: !showOld,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(showOld ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => setState(() => showOld = !showOld),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: newPass,
                      label: "New Password",
                      isPassword: !showNew,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(showNew ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => setState(() => showNew = !showNew),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ===== Update Button =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: CustomButton(
                text: "Update Password",
                isLoading: isLoading,
                onPressed: updatePassword,
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
