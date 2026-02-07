import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yt_music/ytmusic.dart';
import 'package:gyawun/services/settings_manager.dart';

import '../../../../../generated/l10n.dart';
import '../../../../../utils/bottom_modals.dart';
import 'cubit/ytmusic_cubit.dart';

class YTMusicPage extends StatelessWidget {
  const YTMusicPage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return BlocProvider(
      create: (_) => YTMusicCubit(),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _bg,
          textTheme: textTheme,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<YTMusicCubit, YTMusicState>(
              builder: (context, state) {
                final cubit = context.read<YTMusicCubit>();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _section(
                      title: 'GENERAL',
                      children: [
                        _tile(
                          icon: Icons.location_on,
                          title: S.of(context).Country,
                          subtitle: state.location['name'] ?? '-',
                          onTap: () => _pickLocation(context, state.location),
                        ),
                        _tile(
                          icon: Icons.language,
                          title: S.of(context).Language,
                          subtitle: state.language['name'] ?? '-',
                          onTap: () => _pickLanguage(context, state.language),
                        ),
                        _switchTile(
                          icon: Icons.translate,
                          title: S.of(context).Translate_Lyrics,
                          subtitle: 'Auto translate lyrics using app language',
                          value: state.translateLyrics,
                          onChanged: cubit.setTranslateLyrics,
                        ),
                        _switchTile(
                          icon: Icons.autorenew,
                          title: S.of(context).Autofetch_Songs,
                          subtitle: 'Auto queue related songs',
                          value: state.autofetchSongs,
                          onChanged: cubit.setAutofetchSongs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _section(
                      title: 'PLAYBACK and DOWNLOAD',
                      children: [
                        _tile(
                          icon: Icons.spatial_audio,
                          title: S.of(context).Streaming_Quality,
                          subtitle: _cap(state.streamingQuality.name),
                          onTap: () => _pickStreamingQuality(context, state.streamingQuality),
                        ),
                        _tile(
                          icon: Icons.cloud_download,
                          title: S.of(context).DOwnload_Quality,
                          subtitle: _cap(state.downloadQuality.name),
                          onTap: () => _pickDownloadQuality(context, state.downloadQuality),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _section(
                      title: 'PRIVACY',
                      children: [
                        _switchTile(
                          icon: Icons.recommend,
                          title: S.of(context).Personalised_Content,
                          subtitle: 'Use personalized content and recommendations',
                          value: state.personalisedContent,
                          onChanged: (v) async {
                            Modals.showCenterLoadingModal(context);
                            await cubit.setPersonalisedContent(v);
                            if (context.mounted) context.pop();
                          },
                        ),
                        _tile(
                          icon: Icons.edit,
                          title: S.of(context).Enter_Visitor_Id,
                          subtitle: 'Set custom visitor identifier',
                          onTap: () async {
                            final text = await Modals.showTextField(
                              context,
                              title: S.of(context).Enter_Visitor_Id,
                              hintText: S.of(context).Visitor_Id,
                            );
                            if (text != null) cubit.setVisitorId(text);
                          },
                        ),
                        _tile(
                          icon: Icons.key,
                          title: S.of(context).Reset_Visitor_Id,
                          subtitle: state.visitorId.isEmpty ? '-' : state.visitorId,
                          trailing: state.visitorId.isEmpty
                              ? null
                              : InkWell(
                                  onTap: () => Clipboard.setData(ClipboardData(text: state.visitorId)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.copy, size: 18),
                                  ),
                                ),
                          onTap: () async {
                            Modals.showCenterLoadingModal(context);
                            await cubit.resetVisitorId();
                            if (context.mounted) context.pop();
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
              S.of(context).YTMusic.toUpperCase(),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
          Switch(value: value, activeColor: _primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _pickLocation(BuildContext context, Map<String, String> current) async {
    final cubit = context.read<YTMusicCubit>();
    final selected = await _pickMapOption(
      context,
      title: 'Choose Country',
      items: cubit.locations,
      current: current,
    );
    if (selected != null) cubit.setLocation(selected);
  }

  Future<void> _pickLanguage(BuildContext context, Map<String, String> current) async {
    final cubit = context.read<YTMusicCubit>();
    final selected = await _pickMapOption(
      context,
      title: 'Choose Language',
      items: cubit.languages,
      current: current,
    );
    if (selected != null) cubit.setLanguage(selected);
  }

  Future<void> _pickStreamingQuality(BuildContext context, AudioQuality current) async {
    final cubit = context.read<YTMusicCubit>();
    final selected = await _pickEnumOption<AudioQuality>(
      context,
      title: 'Choose Streaming Quality',
      items: cubit.audioQualities,
      current: current,
      label: (v) => _cap(v.name),
    );
    if (selected != null) cubit.setStreamingQuality(selected);
  }

  Future<void> _pickDownloadQuality(BuildContext context, AudioQuality current) async {
    final cubit = context.read<YTMusicCubit>();
    final selected = await _pickEnumOption<AudioQuality>(
      context,
      title: 'Choose Downloading Quality',
      items: cubit.audioQualities,
      current: current,
      label: (v) => _cap(v.name),
    );
    if (selected != null) cubit.setDownloadQuality(selected);
  }

  Future<Map<String, String>?> _pickMapOption(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> items,
    required Map<String, String> current,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              ...items.map((it) {
                final selected = it == current;
                return InkWell(
                  onTap: () => Navigator.pop(ctx, it),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: selected ? _primary : Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text((it['name'] ?? '').trim())),
                        if (selected) const Icon(Icons.check, color: _primary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<T?> _pickEnumOption<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required T current,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              ...items.map((it) {
                final selected = it == current;
                return InkWell(
                  onTap: () => Navigator.pop(ctx, it),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: selected ? _primary : Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(label(it))),
                        if (selected) const Icon(Icons.check, color: _primary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _cap(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
