import 'package:flutter/material.dart';
import 'package:user_app/addproduct.dart';
import 'package:user_app/chat_inbox.dart';
import 'package:user_app/homescreen.dart';
import 'package:user_app/myads.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/theme.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  int _currentIndex = 0;

  final List<Widget> pages = [
    const HomeScreen(),
    const Myads(),
    const Addproduct(),
    const ChatInboxPage(),
    const MyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomAppBar(
        color: AppTheme.card,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, Icons.home_outlined, "Home", 0),
              _navItem(Icons.bookmark, Icons.bookmark_border, "My Ads", 1),

              const SizedBox(width: 48), // space for FAB

              _navItem(Icons.chat_bubble, Icons.chat_bubble_outline, "Chats", 3),
              _navItem(Icons.person, Icons.person_outline, "Profile", 4),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() => _currentIndex = 2);
        },
        child: const Icon(Icons.add, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.primary : AppTheme.textSecondary;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
