import 'package:flutter/material.dart';

class Adaptivecard extends StatelessWidget {
  const Adaptivecard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.margin,
    this.padding,
    this.elevation,
  });

  final Widget child;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.all(1),
      color: backgroundColor ?? Colors.white.withValues(alpha: 0.05),
      elevation: elevation ?? 0,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 2),
          borderRadius: borderRadius ?? BorderRadius.zero),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}
