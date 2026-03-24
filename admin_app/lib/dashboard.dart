import 'package:admin_app/category.dart';
import 'package:admin_app/condition.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/dashboard_content.dart';
import 'package:admin_app/user_management.dart';
import 'package:admin_app/listing_management.dart';
import 'package:admin_app/complaint_management.dart';
import 'package:admin_app/feedback_management.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 👉 IMPORT YOUR LOGIN PAGE HERE
// import 'package:admin_app/login.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({Key? key}) : super(key: key);

  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      backgroundColor: AppTheme.background,
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              backgroundColor: AppTheme.background,
              elevation: 0,
              title: Text(
                _getTitleByIndex(_controller.selectedIndex),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
              leading: IconButton(
                onPressed: () {
                  _key.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu),
              ),
            )
          : null,
      drawer: ExampleSidebarX(controller: _controller),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            ExampleSidebarX(controller: _controller),
          Expanded(
            child: _ScreensExample(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  /// 🔥 LOGOUT FUNCTION
  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Logout",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Are you sure you want to logout?"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();

    /// 👉 CHANGE THIS BASED ON YOUR LOGIN PAGE
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        hoverColor: AppTheme.primary.withOpacity(0.05),
        textStyle: TextStyle(color: AppTheme.textSecondary),
        selectedTextStyle: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 16),
        selectedItemTextPadding: const EdgeInsets.only(left: 16),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          color: AppTheme.primary.withOpacity(0.1),
        ),
        iconTheme: IconThemeData(
          color: AppTheme.textSecondary,
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppTheme.primary,
          size: 22,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 230,
        decoration: BoxDecoration(color: AppTheme.card),
      ),

      /// 🔥 LOGOUT BUTTON HERE
      footerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => logout(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.red),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },

      footerDivider: const Divider(color: AppTheme.divider, height: 1),

      headerBuilder: (context, extended) {
        return SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.padding),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: const Icon(Icons.admin_panel_settings,
                  size: 40, color: AppTheme.primary),
            ),
          ),
        );
      },

      items: [
        SidebarXItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
        SidebarXItem(icon: Icons.people_outline, label: 'User Management'),
        SidebarXItem(icon: Icons.shopping_bag_outlined, label: 'Listings'),
        SidebarXItem(icon: Icons.warning_amber_rounded, label: 'Complaints'),
        SidebarXItem(icon: Icons.rate_review_outlined, label: 'Feedback'),
        SidebarXItem(icon: Icons.category_rounded, label: 'Categories'),
        SidebarXItem(icon: Icons.health_and_safety_rounded, label: 'Conditions'),
      ],
    );
  }
}

class _ScreensExample extends StatelessWidget {
  const _ScreensExample({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        switch (controller.selectedIndex) {
          case 0:
            return const DashboardContent();
          case 1:
            return const UserManagementScreen();
          case 2:
            return const ListingManagementScreen();
          case 3:
            return const ComplaintManagementScreen();
          case 4:
            return const FeedbackManagementScreen();
          case 5:
            return Categories();
          case 6:
            return Condition();
          default:
            return const Center(child: Text("Page Not Found"));
        }
      },
    );
  }
}

String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Dashboard Overview';
    case 1:
      return 'User Management';
    case 2:
      return 'Listing Management';
    case 3:
      return 'Complaints';
    case 4:
      return 'Feedback Overview';
    case 5:
      return 'Categories';
    case 6:
      return 'Conditions';
    default:
      return 'Admin App';
  }
}