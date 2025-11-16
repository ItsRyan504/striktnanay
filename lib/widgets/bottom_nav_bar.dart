import 'package:flutter/material.dart';

enum NavItem {
  home,
  calendar,
  timer,
  checklist,
  profile,
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
            showDate: true,
          ),
          _buildNavButton(
            icon: Icons.timer,
            isActive: currentItem == NavItem.timer,
            onTap: () => onTap(NavItem.timer),
            isCenter: true,
          ),
          _buildNavButton(
            icon: Icons.checklist,
            isActive: currentItem == NavItem.checklist,
            onTap: () => onTap(NavItem.checklist),
          ),
          _buildNavButton(
            icon: Icons.person,
            isActive: currentItem == NavItem.profile,
            onTap: () => onTap(NavItem.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool isCenter = false,
    bool showDate = false,
  }) {
    if (isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0D7377),
              size: 28,
            ),
          ),
        ),
      );
    }

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
              if (showDate)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '31',
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

