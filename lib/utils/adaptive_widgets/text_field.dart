import 'package:flutter/material.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final bool readOnly;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputType? keyboardType;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final BorderRadius borderRadius;
  final double borderWidth;
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.onTap,
    this.contentPadding,
    this.fillColor,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.textInputAction,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.borderRadius = BorderRadius.zero,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF10B981);
    return TextField(
      key: key,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      readOnly: readOnly,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        fillColor: fillColor ?? Colors.white.withValues(alpha: 0.05),
        filled: true,
        contentPadding: contentPadding,
        hintText: hintText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: borderWidth > 0 ? borderWidth : 2),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
