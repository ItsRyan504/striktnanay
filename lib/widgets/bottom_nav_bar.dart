import 'package:flutter/material.dart';

enum NavItem {
  home,
  calendar,
  timer,
  whitelist,
  settings,
}

class BottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onTap;

  const BottomNavBar({
    super.key,
    required this.currentItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF0D7377),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.home,
            isActive: currentItem == NavItem.home,
            onTap: () => onTap(NavItem.home),
          ),
          _buildNavButton(
            icon: Icons.calendar_today,
            isActive: currentItem == NavItem.calendar,
            onTap: () => onTap(NavItem.calendar),
          ),
          _buildNavButton(
            icon: Icons.timer,
            isActive: currentItem == NavItem.timer,
            onTap: () => onTap(NavItem.timer),
          ),
          _buildNavButton(
            icon: Icons.checklist,
            isActive: currentItem == NavItem.whitelist,
            onTap: () => onTap(NavItem.whitelist),
          ),
          _buildNavButton(
            icon: Icons.settings,
            isActive: currentItem == NavItem.settings,
            onTap: () => onTap(NavItem.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

