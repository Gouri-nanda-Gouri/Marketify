import 'package:admin_app/condition.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/place.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:admin_app/category.dart';

void main() {
  runApp(AdminDashboard());
}

class AdminDashboard extends StatelessWidget {
  AdminDashboard({Key? key}) : super(key: key);

  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        canvasColor: canvasColor,
        fontFamily: "Roboto",
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final isSmallScreen = MediaQuery.of(context).size.width < 600;

          return Scaffold(
            key: _key,
            appBar: isSmallScreen
                ? AppBar(
                    backgroundColor: Colors.white,
                    elevation: 1,
                    title: Text(
                      _getTitleByIndex(_controller.selectedIndex),
                      style: const TextStyle(color: Colors.black),
                    ),
                    iconTheme: const IconThemeData(color: Colors.black),
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
                if (!isSmallScreen) ExampleSidebarX(controller: _controller),
                Expanded(
                  child: Center(
                    child: _ScreensExample(
                      controller: _controller,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Color(0x11000000),
              offset: Offset(0, 4),
            ),
          ],
        ),
        hoverColor: accentCanvasColor,
        textStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
        ),
        selectedTextStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 20),
        selectedItemTextPadding: const EdgeInsets.only(left: 20),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accentCanvasColor,
        ),
        iconTheme: IconThemeData(
          color: Colors.black.withOpacity(0.7),
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(
          color: primaryColor,
          size: 22,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 230,
        decoration: BoxDecoration(
          color: canvasColor,
        ),
      ),
      footerDivider: divider,
      headerBuilder: (context, extended) {
        return SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset('assets/p1.jpg'),
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.home_rounded,
          label: 'Home',
          onTap: () {
            debugPrint('Home');
          },
        ),
        const SidebarXItem(
          icon: Icons.category_rounded,
          label: 'Categories',
        ),
        const SidebarXItem(
          icon: Icons.health_and_safety_rounded,
          label: 'Conditions',
        ),
        SidebarXItem(
          icon: Icons.location_on_outlined,
          label: 'Districts',
          
        ),
       SidebarXItem(
          icon: Icons.location_city,
          label: 'Places',
         
        ),
        const SidebarXItem(
          iconWidget: FlutterLogo(size: 22),
          label: 'Flutter',
        ),

      ],
    );
  }

  void _showDisabledAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Item disabled for selecting',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
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
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                height: 110,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                ),
              ),
            );

          case 1:
            return Categories();

          case 2:
            return Condition();
          case 3:
          return District();
          case 4:
          return Place();

          default:
            return const Center(
              child: Text("Page Not Found"),
            );
        }
      },
    );
  }
}



String _getTitleByIndex(int index) {
  switch (index) {
    case 0:
      return 'Home';
    case 1:
      return 'Categories';
    case 2:
      return 'Conditions';
    case 3:
      return 'District';
      case 4:
      return 'Places';
    case 5:
      return 'Flutter';
    default:
      return 'Page';
  }
}

const primaryColor = Color(0xFF2E6CF6);
const canvasColor = Colors.white;
const scaffoldBackgroundColor = Color(0xFFF4F6FB);
const accentCanvasColor = Color(0xFFE9EEFF);

final divider = Divider(
  color: Colors.grey.withOpacity(0.2),
  height: 1,
);
