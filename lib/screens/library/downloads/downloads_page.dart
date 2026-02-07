import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/downloads_cubit.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadsCubit()..load(),
      child: const _DownloadsView(),
    );
  }
}

class _DownloadsView extends StatelessWidget {
  const _DownloadsView();

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
                child: BlocBuilder<DownloadsCubit, DownloadsState>(
                  builder: (context, state) {
                    if (state is DownloadsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is DownloadsError) {
                      return Center(child: Text(state.message));
                    }

                    final playlists = (state as DownloadsLoaded).playlists;
                    final entries = playlists.entries.where((e) => e.value is Map).toList()
                      ..sort((a, b) {
                        if (a.key == DownloadManager.songsPlaylistId) return -1;
                        if (b.key == DownloadManager.songsPlaylistId) return 1;
                        return ((a.value['title'] ?? '').toString())
                            .compareTo((b.value['title'] ?? '').toString());
                      });

                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'No downloads yet.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final playlist = Map<String, dynamic>.from(entries[index].value);
                        final songs = (playlist['songs'] as List?) ?? const [];
                        final isSongs = playlist['type'] == 'SONGS';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '/library/downloads/download_playlist',
                                extra: {'playlistId': playlist['id']},
                              );
                            },
                            onLongPress: () {
                              Modals.showDownloadDetailsBottomModal(context, playlist);
                            },
                            child: Container(
                              height: 92,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border(
                                  left: BorderSide(
                                    color: index == 0 ? _primary : Colors.white.withValues(alpha: 0.15),
                                    width: index == 0 ? 4 : 2,
                                  ),
                                  top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 92,
                                    height: double.infinity,
                                    child: _coverForPlaylist(playlist),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (isSongs ? 'SONGS' : (playlist['title'] ?? 'UNTITLED').toString())
                                                .toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: index == 0 ? _primary : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${songs.length} ${songs.length == 1 ? 'TRACK' : 'TRACKS'}',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'DOWNLOADS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.4,
              ),
            ),
          ),
          InkWell(
            onTap: () => Modals.showDownloadBottomModal(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverForPlaylist(Map<String, dynamic> playlist) {
    final songs = (playlist['songs'] as List?) ?? const [];

    String? url;
    if (songs.isNotEmpty && songs.first is Map) {
      final thumbs = ((songs.first as Map)['thumbnails'] as List?) ?? const [];
      if (thumbs.isNotEmpty) {
        url = (thumbs.first['url'] ?? '').toString();
      }
    }

    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.1),
        child: const Icon(Icons.music_note, color: Colors.white),
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
}
