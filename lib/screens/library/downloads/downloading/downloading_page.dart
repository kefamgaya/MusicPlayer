import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/downloading_cubit.dart';

class DownloadingPage extends StatelessWidget {
  const DownloadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadingCubit()..load(),
      child: const _DownloadingView(),
    );
  }
}

class _DownloadingView extends StatelessWidget {
  const _DownloadingView();

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: BlocBuilder<DownloadingCubit, DownloadingState>(
                  builder: (context, state) {
                    if (state is DownloadingLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is DownloadingError) {
                      return Center(child: Text(state.message));
                    }

                    final data = state as DownloadingLoaded;
                    final downloading = data.downloading.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
                    final queued = data.queued.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

                    if (downloading.isEmpty && queued.isEmpty) {
                      return Center(
                        child: Text(
                          'No active downloads.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        if (downloading.isNotEmpty) ...[
                          _sectionLabel('IN PROGRESS'),
                          const SizedBox(height: 10),
                          ...downloading.indexed.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _downloadItemTile(
                                context: context,
                                song: entry.$2,
                                highlight: entry.$1 == 0,
                                isQueued: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (queued.isNotEmpty) ...[
                          _sectionLabel('QUEUED // ${queued.length}'),
                          const SizedBox(height: 10),
                          ...queued.map(
                            (song) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _downloadItemTile(
                                context: context,
                                song: song,
                                isQueued: true,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
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
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2)),
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
              'DOWNLOADING',
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

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceMono(
        fontSize: 11,
        letterSpacing: 2.4,
        color: Colors.white.withValues(alpha: 0.45),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _downloadItemTile({
    required BuildContext context,
    required Map<String, dynamic> song,
    bool highlight = false,
    bool isQueued = false,
  }) {
    final id = (song['videoId'] ?? '').toString();
    final progressNotifier = GetIt.I<DownloadManager>().getProgressNotifier(id);

    return InkWell(
      onLongPress: () => Modals.showSongBottomModal(context, song),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            left: BorderSide(
              color: highlight ? _primary : Colors.white.withValues(alpha: 0.15),
              width: highlight ? 4 : 2,
            ),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 94, height: double.infinity, child: _cover(song)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(song).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(song).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isQueued)
                      Text(
                        'QUEUED',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      )
                    else
                      ValueListenableBuilder<double>(
                        valueListenable: progressNotifier ?? ValueNotifier(0.0),
                        builder: (_, v, __) {
                          final pct = (v.clamp(0, 1) * 100).toStringAsFixed(0);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pct%',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 6,
                                width: 180,
                                color: Colors.white.withValues(alpha: 0.12),
                                child: FractionallySizedBox(
                                  widthFactor: v.clamp(0, 1),
                                  child: Container(color: _primary),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isQueued ? Icons.schedule : Icons.downloading,
                color: isQueued ? Colors.white.withValues(alpha: 0.25) : _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(Map<String, dynamic> song) {
    final thumbs = (song['thumbnails'] as List?) ?? const [];
    if (thumbs.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.1),
        child: const Icon(Icons.music_note),
      );
    }
    final url = (thumbs.first['url'] ?? '').toString();
    if (url.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.1),
        child: const Icon(Icons.music_note),
      );
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Image.network(url, fit: BoxFit.cover),
    );
  }

  String _title(Map<String, dynamic> song) => (song['title'] ?? 'Unknown').toString();

  String _subtitle(Map<String, dynamic> song) {
    final subtitle = song['subtitle']?.toString();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    if (song['artists'] is List) {
      final names = (song['artists'] as List)
          .map((e) => (e is Map ? e['name'] : null)?.toString())
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) return names;
    }
    return 'Unknown Artist';
  }
}
