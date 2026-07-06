import 'package:flutter/material.dart';
import '../../core/theme.dart';

final class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTextStyles.titleMd),
      actions: actions,
      leading: leading ?? (showBack ? const BackButton() : null),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
