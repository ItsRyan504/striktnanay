import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'timer_screen.dart';
import 'checklist_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  NavItem _currentNavItem = NavItem.home;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const TimerScreen(),
    const ChecklistScreen(),
    const ProfileScreen(),
  ];

  void _onNavItemTapped(NavItem item) {
    setState(() {
      _currentNavItem = item;
      _currentIndex = item.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentItem: _currentNavItem,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

