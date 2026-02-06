import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        const SnackBar(content: Text("All fields are required")),
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
          const SnackBar(content: Text("Old password incorrect")),
        );
        setState(() => isLoading = false);
        return;
      }

      await supabase.from('tbl_user').update({
        'user_password': newPass.text.trim(),
      }).eq('id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Password update error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ===== Icon =====
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 42,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Update your password",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Choose a strong password for better security",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 28),

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
                    _passwordField(
                      controller: oldPass,
                      label: "Old Password",
                      isVisible: showOld,
                      toggle: () =>
                          setState(() => showOld = !showOld),
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      controller: newPass,
                      label: "New Password",
                      isVisible: showNew,
                      toggle: () =>
                          setState(() => showNew = !showNew),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ===== Update Button =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: isLoading ? null : updatePassword,
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
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Update Password",
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

// ===== Password Field =====
Widget _passwordField({
  required TextEditingController controller,
  required String label,
  required bool isVisible,
  required VoidCallback toggle,
}) {
  return TextField(
    controller: controller,
    obscureText: !isVisible,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: toggle,
      ),
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
