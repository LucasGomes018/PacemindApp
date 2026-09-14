import 'package:flutter/material.dart';

class BottomMenu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = const [
      _MenuItemData(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: "Início",
      ),
      _MenuItemData(
        icon: Icons.directions_run_outlined,
        activeIcon: Icons.directions_run_rounded,
        label: "Corrida",
      ),
      _MenuItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: "Treinos",
      ),
      _MenuItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: "Perfil",
      ),
    ];

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF131C2E).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : const Color(0xFF0066FF).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: _buildItem(
                context: context,
                item: item,
                index: index,
                isSelected: isSelected,
                isDark: isDark,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required _MenuItemData item,
    required int index,
    required bool isSelected,
    required bool isDark,
  }) {
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF0066FF).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF0066FF).withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF1E70EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? Colors.white : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : inactiveColor,
                    letterSpacing: isSelected ? 0.2 : 0,
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

class _MenuItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _MenuItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}