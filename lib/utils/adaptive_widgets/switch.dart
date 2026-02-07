import 'package:flutter/material.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  const AdaptiveSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return const _ThemedSwitch().build(value, onChanged);
  }
}

class _ThemedSwitch {
  const _ThemedSwitch();

  Widget build(bool value, ValueChanged<bool>? onChanged) {
    return Switch(
      value: value,
      activeColor: const Color(0xFF10B981),
      onChanged: onChanged,
    );
  }
}
