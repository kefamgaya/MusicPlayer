import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit()..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  bool _highlightLatest = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);
    final mono = GoogleFonts.jetBrainsMono();

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: InternetGuard(
        child: Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HISTORY',
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _highlightLatest = !_highlightLatest;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: _primary, width: 2),
                            ),
                            child: const Icon(Icons.filter_list, color: _primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
                  if (state is HistoryLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is HistoryError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(state.message)),
                    );
                  }

                  final songs = (state as HistoryLoaded)
                      .songs
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  if (songs.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No history yet.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isFirst = index == 0;
                      return _historyRow(
                        song: song,
                        mono: mono,
                        textTheme: textTheme,
                        highlight: _highlightLatest && isFirst,
                      );
                    },
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow({
    required Map<String, dynamic> song,
    required TextStyle mono,
    required TextTheme textTheme,
    required bool highlight,
  }) {
    final updatedAt = song['updatedAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(song['updatedAt'] as int)
        : null;
    final playedAt = updatedAt == null ? '--:--' : DateFormat('HH:mm').format(updatedAt);

    return InkWell(
      onTap: () async {
        await GetIt.I<MediaPlayer>().playSong(Map.from(song));
      },
      onLongPress: () => Modals.showSongBottomModal(context, song),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            if (highlight) Container(width: 4, color: _primary),
            SizedBox(
              width: 112,
              height: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                child: ColorFiltered(
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
                  child: _cover(song),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (song['title'] ?? '').toString().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(song).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'PLAYED AT $playedAt',
                          style: mono.copyWith(
                            fontSize: 10,
                            color: highlight
                                ? _primary
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _duration(song),
                          style: mono.copyWith(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => Modals.showSongBottomModal(context, song),
              icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.25)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(Map<String, dynamic> song) {
    final thumbs = (song['thumbnails'] as List?) ?? const [];
    if (thumbs.isEmpty) {
      return const ColoredBox(
        color: Color(0x22000000),
        child: Icon(Icons.music_note),
      );
    }
    final url = (thumbs.first['url'] ?? '').toString();
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0x22000000),
        child: Icon(Icons.music_note),
      );
    }
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
  }

  String _subtitle(Map<String, dynamic> song) {
    final subtitle = song['subtitle']?.toString();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    if (song['artists'] is List) {
      final names = (song['artists'] as List)
          .map((e) => (e is Map ? e['name'] : null)?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .join(', ');
      if (names.isNotEmpty) return names;
    }
    return 'Unknown Artist';
  }

  String _duration(Map<String, dynamic> song) {
    if (song['duration'] != null) return song['duration'].toString();
    final seconds = int.tryParse(song['durationInSeconds']?.toString() ?? '');
    if (seconds == null) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
