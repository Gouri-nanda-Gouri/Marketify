import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    // HomeScreen(),
    // ChatsScreen(),
    // AddListingScreen(),
    // MyAdsScreen(),
    // ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    return Scaffold(
      body: pages[index],

      // ✅ OLX-style floating bottom nav
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 22,
                  color: Color(0x22000000),
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  isSelected: index == 0,
                  label: "Home",
                  icon: Icons.home_outlined,
                  selectedColor: primaryBlue,
                  onTap: () => setState(() => index = 0),
                ),
                _NavItem(
                  isSelected: index == 1,
                  label: "Chats",
                  icon: Icons.chat_bubble_outline,
                  selectedColor: primaryBlue,
                  onTap: () => setState(() => index = 1),
                ),

                // ✅ Center Sell button (bigger + floating feel)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => index = 2),
                    child: Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            color: Color(0x33000000),
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),

                _NavItem(
                  isSelected: index == 3,
                  label: "My Ads",
                  icon: Icons.inventory_2_outlined,
                  selectedColor: primaryBlue,
                  onTap: () => setState(() => index = 3),
                ),
                _NavItem(
                  isSelected: index == 4,
                  label: "Profile",
                  icon: Icons.person_outline,
                  selectedColor: primaryBlue,
                  onTap: () => setState(() => index = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isSelected;
  final String label;
  final IconData icon;
  final Color selectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.isSelected,
    required this.label,
    required this.icon,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? selectedColor : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? selectedColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
