import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smart_box/screens/box/AddPage.dart';
import 'package:smart_box/screens/home_content.dart';
import 'package:smart_box/screens/notifications.dart';
import 'package:smart_box/screens/profile.dart';

class NavigationWrapper extends StatefulWidget {
  final Map<String, dynamic> user;

  const NavigationWrapper({super.key, required this.user});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(user: widget.user),       // Index 0 — Boxes
      AddPage(),                           // Index 1 — Add
      NotificationsPage(),                // Index 2
      ProfilePage(user: widget.user),    // Index 3
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        selectedItemColor: const Color(0xFF006FFD),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.explore,
              color: _selectedIndex == 0 ? const Color(0xFF006FFD) : Colors.grey,
            ),
            label: 'Menue',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.edit,
              color: _selectedIndex == 1 ? const Color(0xFF006FFD) : Colors.grey,
            ),
            label: 'Boxes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LucideIcons.bell,
              color: _selectedIndex == 2 ? const Color(0xFF006FFD) : Colors.grey,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 3 ? const Color(0xFF006FFD) : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
