import 'package:flutter/material.dart';

import 'icons.dart';

class AdaptiveButton extends StatelessWidget {
  final Widget child;
  final void Function()? onPressed;
  final Color? color;
  const AdaptiveButton(
      {super.key, required this.child, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
        foregroundColor: primary,
      ),
      child: child,
    );
  }
}

class AdaptiveFilledButton extends StatelessWidget {
  final Widget child;
  final void Function()? onPressed;
  final Color? color;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;
  const AdaptiveFilledButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.shape,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    return FilledButton(
      key: key,
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color ?? primary),
        shape: WidgetStateProperty.all(shape ?? const RoundedRectangleBorder()),
        padding: WidgetStateProperty.all(padding),
        foregroundColor: WidgetStateProperty.all(Colors.black),
      ),
      child: child,
    );
  }
}

class AdaptiveOutlinedButton extends StatelessWidget {
  final Widget child;
  final void Function()? onPressed;
  final Color? color;
  const AdaptiveOutlinedButton(
      {super.key, required this.child, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: ButtonStyle(
          backgroundColor:
              color != null ? WidgetStateProperty.all(color) : null,
          foregroundColor: WidgetStateProperty.all(primary),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
          side: WidgetStateProperty.all(
            BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
          )),
      child: child,
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isSelected,
    this.color,
  });
  final Widget icon;
  final void Function()? onPressed;
  final bool? isSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    return IconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      isSelected: isSelected,
      color: color ?? primary,
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class AdaptiveBackButton extends StatelessWidget {
  const AdaptiveBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveIconButton(
      icon: Icon(AdaptiveIcons.back),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
