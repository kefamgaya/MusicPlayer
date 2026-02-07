import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/bottom_message.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import '../../../../generated/l10n.dart';
import 'cubit/privacy_cubit.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => PrivacyCubit(),
      child: BlocListener<PrivacyCubit, PrivacyState>(
        listenWhen: (_, state) => state.lastAction != null,
        listener: (context, state) {
          final action = state.lastAction;
          if (action == null) return;
          if (action == PrivacyAction.playbackDeleted) {
            BottomMessage.showText(context, S.of(context).Playback_History_Deleted);
          } else if (action == PrivacyAction.searchDeleted) {
            BottomMessage.showText(context, S.of(context).Search_History_Deleted);
          }
          context.read<PrivacyCubit>().consumeAction();
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: _bg,
            textTheme: textTheme,
          ),
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              bottom: false,
              child: BlocBuilder<PrivacyCubit, PrivacyState>(
                builder: (context, state) {
                  final cubit = context.read<PrivacyCubit>();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _header(context),
                      const SizedBox(height: 14),
                      _section(
                        title: 'PLAYBACK',
                        children: [
                          _switchTile(
                            icon: Icons.play_arrow,
                            title: S.of(context).Enable_Playback_History,
                            subtitle: 'Store recently played tracks',
                            value: state.playbackHistory,
                            onChanged: cubit.togglePlaybackHistory,
                          ),
                          _dangerTile(
                            icon: Icons.history_toggle_off,
                            title: S.of(context).Delete_Playback_History,
                            subtitle: 'Remove all playback history entries',
                            onTap: () async {
                              final confirm = await Modals.showConfirmBottomModal(
                                context,
                                message: S.of(context).Delete_Playback_History_Confirm_Message,
                                isDanger: true,
                              );
                              if (confirm == true) cubit.clearPlaybackHistory();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: 'SEARCH',
                        children: [
                          _switchTile(
                            icon: Icons.saved_search,
                            title: S.of(context).Enable_Search_History,
                            subtitle: 'Store your search suggestions',
                            value: state.searchHistory,
                            onChanged: cubit.toggleSearchHistory,
                          ),
                          _dangerTile(
                            icon: Icons.delete_sweep,
                            title: S.of(context).Delete_Search_History,
                            subtitle: 'Remove all search history entries',
                            onTap: () async {
                              final confirm = await Modals.showConfirmBottomModal(
                                context,
                                message: S.of(context).Delete_Search_History_Confirm_Message,
                                isDanger: true,
                              );
                              if (confirm == true) cubit.clearSearchHistory();
                            },
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
              'PRIVACY',
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

  Widget _dangerTile({
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
              color: const Color(0x66B00020),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
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
            Icon(icon, color: Colors.red.withValues(alpha: 0.9), size: 20),
          ],
        ),
      ),
    );
  }
}
