import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Hamburger icon that opens the nearest [Scaffold]'s drawer — used in the
/// header of every top-level screen (Home, Browse, Learning, Messages,
/// Profile) since the app has no persistent app bar of its own.
class ZLMenuButton extends StatelessWidget {
  final Color? iconColor;
  final Color? borderColor;

  const ZLMenuButton({super.key, this.iconColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
        ),
        child: Icon(Icons.menu_rounded, size: 19, color: iconColor ?? AppColors.ink),
      ),
    );
  }
}
