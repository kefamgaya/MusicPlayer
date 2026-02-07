import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/update_service/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';
import 'cubit/settings_system_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => SettingsSystemCubit()..load(),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _bg,
          textTheme: textTheme,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<SettingsSystemCubit, SettingsSystemState>(
              builder: (context, state) {
                final batteryDisabled =
                    state is SettingsSystemLoaded ? state.isBatteryOptimizationDisabled : null;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    if (Platform.isAndroid && batteryDisabled != true)
                      _BatteryWarningTile(
                        onTap: () => context.read<SettingsSystemCubit>().requestBatteryOptimizationIgnore(),
                      ),
                    if (Platform.isAndroid && batteryDisabled != true) const SizedBox(height: 16),

                    _SectionCard(
                      title: 'GENERAL',
                      children: [
                        _SettingTile(
                          icon: Icons.palette,
                          iconColor: const Color(0xFFB75676),
                          title: S.of(context).Appearence,
                          subtitle: 'Themes, layout, and visual style',
                          onTap: () => context.go('/settings/appearance'),
                        ),
                        _SettingTile(
                          icon: Icons.play_circle_fill,
                          iconColor: const Color(0xFF465C8D),
                          title: 'Player',
                          subtitle: 'Audio effects and playback',
                          onTap: () => context.go('/settings/player'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: 'SERVICES',
                      children: [
                        _SettingTile(
                          icon: Icons.smart_display,
                          iconColor: const Color(0xFFB53636),
                          title: 'Youtube Music',
                          subtitle: 'Content region, language, audio quality',
                          onTap: () => context.go('/settings/services/ytmusic'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: 'STORAGE and PRIVACY',
                      children: [
                        _SettingTile(
                          icon: Icons.storage,
                          iconColor: const Color(0xFF829242),
                          title: 'Backup and storage',
                          subtitle: 'App folder, backup, and restore',
                          onTap: () => context.go('/settings/backup_storage'),
                        ),
                        _SettingTile(
                          icon: Icons.shield,
                          iconColor: const Color(0xFF2E734C),
                          title: 'Privacy',
                          subtitle: 'Playback and search history',
                          onTap: () => context.go('/settings/privacy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _SectionCard(
                      title: 'UPDATES and ABOUT',
                      children: [
                        _SettingTile(
                          icon: Icons.info,
                          iconColor: const Color(0xFF73542E),
                          title: S.of(context).About,
                          subtitle: 'App info, support and links',
                          onTap: () => context.go('/settings/about'),
                        ),
                        _SettingTile(
                          icon: Icons.system_update,
                          iconColor: const Color(0xFF732E3E),
                          title: S.of(context).Check_For_Update,
                          subtitle: 'Check GitHub for releases',
                          onTap: () => UpdateService.manualCheck(context),
                        ),
                        _SettingTile(
                          icon: Icons.payments,
                          iconColor: const Color(0xFF2E6473),
                          title: S.of(context).Donate,
                          subtitle: S.of(context).Donate_Message,
                          onTap: () => showPaymentsModal(context),
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
      ),
      child: Row(
        children: const [
          Icon(Icons.tune, color: _primary),
          SizedBox(width: 10),
          Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
              border: Border(left: BorderSide(color: SettingsPage._primary, width: 4)),
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
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              color: iconColor.withValues(alpha: 0.35),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
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
}

class _BatteryWarningTile extends StatelessWidget {
  const _BatteryWarningTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x55B00020),
          border: Border.all(color: const Color(0xFFB00020), width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.battery_alert, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.of(context).Battery_Optimisation_message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showPaymentsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0A0A0A),
    shape: const RoundedRectangleBorder(),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _payTile(
              context,
              title: S.of(context).Pay_With_UPI,
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(const ClipboardData(text: 'sheikhhaziq76@okaxis'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied UPI ID to clipboard!')),
                  );
                }
              },
            ),
            _payTile(
              context,
              title: S.of(context).Support_Me_On_Kofi,
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(
                  Uri.parse('https://ko-fi.com/sheikhhaziq'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            _payTile(
              context,
              title: S.of(context).Buy_Me_A_Coffee,
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(
                  Uri.parse('https://buymeacoffee.com/sheikhhaziq'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _payTile(
  BuildContext context, {
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments, color: SettingsPage._primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
        ],
      ),
    ),
  );
}
