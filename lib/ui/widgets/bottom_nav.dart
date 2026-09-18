import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../theme/app_theme.dart';

class EchoraBottomNav extends StatelessWidget {
  const EchoraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.md,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: Strings.navHome,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: Strings.navProfile,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.violet;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            height: AppSize.bottomNavItem,
            decoration: BoxDecoration(
              color: selected ? accent.tint : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? accent.base : colors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: context.typography.label.copyWith(
                    color: selected ? accent.onTint : colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
