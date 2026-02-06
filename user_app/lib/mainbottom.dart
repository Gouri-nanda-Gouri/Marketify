import 'package:flutter/material.dart';
import 'package:user_app/addproduct.dart';
import 'package:user_app/homescreen.dart';
import 'package:user_app/myprofile.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  int _currentIndex = 0;

  final pages = const [
    HomeScreen(),
    Center(child: Text("Search")),
    Addproduct(),
    Center(child: Text("Chats")),
    MyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    return Scaffold(
      body: pages[_currentIndex],

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, "Home", 0),
              _navItem(Icons.collections_bookmark_outlined, "My Ads", 1),

              const SizedBox(width: 36), // space for FAB

              _navItem(Icons.chat_bubble_outline, "Chats", 3),
              _navItem(Icons.person_outline, "Profile", 4),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: () {
          setState(() => _currentIndex = 2);
        },
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2E6CF6) : Colors.black54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF2E6CF6) : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
