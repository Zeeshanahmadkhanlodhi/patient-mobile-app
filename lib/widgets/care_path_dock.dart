import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Floating CarePath bar with frost blur and a raised center Book action.
class CarePathDock extends StatelessWidget {
  const CarePathDock({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onBook,
    this.unread = 0,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onBook;
  final int unread;

  static const double barHeight = 62;
  static const double fabSize = 58;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // Sit closer to the bottom edge (into the home-indicator band a bit).
    final bottomGap = safeBottom > 0 ? 6.0 : 4.0;
    final topFade = 28.0;

    return SizedBox(
      height: barHeight + fabSize * 0.42 + bottomGap + topFade,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Soft fade so scrolling content dissolves under the dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomGap + topFade + 8,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.cream.withValues(alpha: 0),
                      AppColors.cream.withValues(alpha: 0.55),
                      AppColors.cream.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Frosted floating bar
          Positioned(
            left: 14,
            right: 14,
            bottom: bottomGap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0E4B4C),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          selected: index == 0,
                          onTap: () => onChanged(0),
                        ),
                        _Tab(
                          icon: Icons.folder_open_outlined,
                          activeIcon: Icons.folder_rounded,
                          label: 'Records',
                          selected: index == 1,
                          onTap: () => onChanged(1),
                        ),
                        const SizedBox(width: fabSize),
                        _Tab(
                          icon: Icons.chat_bubble_outline_rounded,
                          activeIcon: Icons.chat_bubble_rounded,
                          label: 'Inbox',
                          selected: index == 2,
                          badge: unread > 0 ? (unread > 9 ? '9+' : '$unread') : null,
                          onTap: () => onChanged(2),
                        ),
                        _Tab(
                          icon: Icons.grid_view_outlined,
                          activeIcon: Icons.grid_view_rounded,
                          label: 'More',
                          selected: index == 3,
                          onTap: () => onChanged(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Raised Book button
          Positioned(
            bottom: bottomGap + barHeight - fabSize * 0.58,
            child: GestureDetector(
              onTap: onBook,
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.tealSoft, AppColors.teal, AppColors.tealDeep],
                  ),
                  border: Border.all(color: AppColors.cream, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x400E4B4C),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    Text(
                      'Book',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : AppColors.muted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.tealMist.withValues(alpha: 0.95) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(selected ? activeIcon : icon, size: 20, color: color),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
