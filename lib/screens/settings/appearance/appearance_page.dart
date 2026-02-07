import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/settings_manager.dart';

import '../../../generated/l10n.dart';
import 'cubit/appearance_cubit.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => AppearanceCubit(),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _bg,
          textTheme: textTheme,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<AppearanceCubit, AppearanceState>(
              builder: (context, state) {
                final s = state as AppearanceLoaded;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _section(
                      title: 'THEME',
                      children: [
                        _tile(
                          icon: Icons.dark_mode,
                          title: S.of(context).Theme_Mode,
                          subtitle: _themeLabel(s.themeMode),
                          trailing: _smallTag('CHANGE'),
                          onTap: () => _pickTheme(context, s.themeMode),
                        ),
                        _tile(
                          icon: Icons.color_lens,
                          title: 'Accent Color',
                          subtitle: 'Primary app accent',
                          trailing: _colorPreview(s.accentColor),
                          onTap: () => _pickAccent(context, s.accentColor),
                        ),
                        _switchTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Amoled Black',
                          subtitle: 'Pure black background in dark mode',
                          value: s.amoledBlack,
                          onChanged: context.read<AppearanceCubit>().setAmoledBlack,
                        ),
                        _switchTile(
                          icon: Icons.palette_outlined,
                          title: S.of(context).Dynamic_Colors,
                          subtitle: 'Use system generated color scheme',
                          value: s.dynamicColors,
                          onChanged: context.read<AppearanceCubit>().setDynamicColors,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2)),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).Appearence.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _primary, width: 4)),
            ),
            child: Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 2.2,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              color: _primary.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.58)),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            color: _primary.withValues(alpha: 0.2),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.58)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _colorPreview(Color? color) {
    final c = color ?? Colors.white;
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)),
      child: Row(
        children: [
          Expanded(child: Container(color: c)),
          Expanded(child: Container(color: c.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System Default';
    }
  }

  Future<void> _pickTheme(BuildContext context, ThemeMode current) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pickThemeTile(ctx, 'System Default', ThemeMode.system, current),
              _pickThemeTile(ctx, 'Light Mode', ThemeMode.light, current),
              _pickThemeTile(ctx, 'Dark Mode', ThemeMode.dark, current),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await context.read<AppearanceCubit>().setThemeMode(selected);
    }
  }

  Widget _pickThemeTile(
    BuildContext context,
    String label,
    ThemeMode value,
    ThemeMode current,
  ) {
    final selected = value == current;
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: selected ? _primary : Colors.white.withValues(alpha: 0.15), width: 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (selected) const Icon(Icons.check, color: _primary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAccent(BuildContext context, Color? current) async {
    const presets = <Color>[
      Color(0xFF10B981),
      Color(0xFF10B748),
      Color(0xFF22C55E),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF6366F1),
      Color(0xFFFFFFFF),
    ];

    final selected = await showModalBottomSheet<Color?>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...presets.map((c) {
                final active = current == c;
                return InkWell(
                  onTap: () => Navigator.pop(ctx, c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      border: Border.all(
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.25),
                        width: active ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () => Navigator.pop(ctx, null),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                  ),
                  child: const Icon(Icons.block, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null || current != null) {
      GetIt.I<SettingsManager>().accentColor = selected;
    }
  }
}
