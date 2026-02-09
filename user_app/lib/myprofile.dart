import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/changepassword.dart';
import 'package:user_app/editprofile.dart';
import 'package:user_app/my_favo.dart';
import 'main.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  Future<void> fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('tbl_user')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          userData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text("Profile not found")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 30),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage:
                          NetworkImage(userData!['user_photo']),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userData!['user_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userData!['user_email'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== Details Card =====
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
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoTile(
                      Icons.phone,
                      "Phone",
                      userData!['user_contact'],
                    ),
                    const Divider(height: 28),
                    _infoTile(
                      Icons.location_on,
                      "Address",
                      userData!['user_address'],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ===== Action Buttons =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _actionButton(
                    icon: Icons.edit,
                    text: "Edit Profile",
                    color: primaryBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfile(userData: userData!),
                      ),
                    ).then((_) => fetchProfile()),
                  ),
                  const SizedBox(height: 14),
_actionButton(
  icon: Icons.lock_outline,
  text: "Change Password",
  color: Colors.orange,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangePassword(
        userId: supabase.auth.currentUser!.id,
      ),
    ),
  ),
),
const SizedBox(height: 14),
_actionButton(
  icon: Icons.favorite,
  text: "My Favourites",
  color: Colors.pinkAccent,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MyFavourites()),
  ),
),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ===== Helper Widgets =====

Widget _infoTile(IconData icon, String label, String value) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E6CF6)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _actionButton({
  required IconData icon,
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: color.withOpacity(0.35),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
