import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/changepassword.dart';
import 'package:user_app/editprofile.dart';
import 'package:user_app/main.dart';
import 'package:user_app/my_favo.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'package:user_app/complaint.dart';
import 'package:user_app/feedback.dart';

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
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: Text("Profile not found")),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Header =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppTheme.padding, 60, AppTheme.padding, 30),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadiusLarge),
                  bottomRight: Radius.circular(AppTheme.borderRadiusLarge),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppTheme.background,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userData!['user_photo'] ?? ''),
                      onBackgroundImageError: (_, __) {},
                      child: userData!['user_photo'] == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData!['user_name'] ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userData!['user_email'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== Details Card =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: CustomCard(
                child: Column(
                  children: [
                    _infoTile(
                      Icons.phone_outlined,
                      "Phone",
                      userData!['user_contact'] ?? 'Not provided',
                    ),
                    const Divider(height: 32, color: AppTheme.divider),
                    _infoTile(
                      Icons.location_on_outlined,
                      "Address",
                      userData!['user_address'] ?? 'Not provided',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

             // ===== Action Buttons =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Column(
                children: [
                  CustomButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    text: "Edit Profile",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfile(userData: userData!),
                      ),
                    ).then((_) => fetchProfile()),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    icon: const Icon(Icons.lock_outline, size: 20),
                    text: "Change Password",
                    isSecondary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePassword(
                          userId: Supabase.instance.client.auth.currentUser!.id,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    icon: const Icon(Icons.favorite_border, size: 20),
                    text: "My Favourites",
                    isSecondary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyFavourites()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    icon: const Icon(Icons.support_agent_outlined, size: 20),
                    text: "My Complaints",
                    isSecondary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ComplaintListScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    icon: const Icon(Icons.rate_review_outlined, size: 20),
                    text: "My Feedback",
                    isSecondary: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackListScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
