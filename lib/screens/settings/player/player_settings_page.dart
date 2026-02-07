import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../generated/l10n.dart';
import 'cubit/player_settings_cubit.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => PlayerSettingsCubit(),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _bg,
          textTheme: textTheme,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<PlayerSettingsCubit, PlayerSettingsState>(
              builder: (context, state) {
                final s = state as PlayerSettingsLoaded;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _section(
                      title: 'PLAYBACK',
                      children: [
                        _tile(
                          icon: Icons.equalizer,
                          title: S.of(context).Loudness_And_Equalizer,
                          subtitle: 'Audio tuning and enhancement',
                          onTap: () => context.go('/settings/player/equalizer'),
                        ),
                        _switchTile(
                          icon: Icons.fast_forward,
                          title: S.of(context).Skip_Silence,
                          subtitle: 'Automatically skip silent segments',
                          value: s.skipSilence,
                          onChanged: context.read<PlayerSettingsCubit>().setSkipSilence,
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
              'PLAYER',
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
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
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
          Switch(value: value, activeColor: _primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
