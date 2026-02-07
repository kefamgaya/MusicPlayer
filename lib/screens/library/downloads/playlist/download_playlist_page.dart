import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/download_playlist_cubit.dart';

class DownloadPlaylistPage extends StatelessWidget {
  const DownloadPlaylistPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadPlaylistCubit(playlistId)..load(),
      child: _DownloadPlaylistView(playlistId: playlistId),
    );
  }
}

class _DownloadPlaylistView extends StatelessWidget {
  const _DownloadPlaylistView({required this.playlistId});

  final String playlistId;

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
        body: BlocBuilder<DownloadPlaylistCubit, DownloadPlaylistState>(
          builder: (context, state) {
            if (state is DownloadPlaylistLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DownloadPlaylistError) {
              return Center(child: Text(state.message));
            }

            final data = state as DownloadPlaylistLoaded;
            final playlist = Map<String, dynamic>.from(data.playlist);
            final songs = data.songs
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            final totalSeconds = songs.fold<int>(
              0,
              (sum, e) => sum + (int.tryParse(e['durationInSeconds']?.toString() ?? '0') ?? 0),
            );
            final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _iconBtn(
                            icon: Icons.arrow_back,
                            onTap: () => context.pop(),
                          ),
                          Text(
                            'COLLECTION // ${playlistId.substring(((playlistId.length - 3).clamp(0, playlistId.length)) as int)}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: _primary,
                              letterSpacing: 2,
                            ),
                          ),
                          _iconBtn(
                            icon: Icons.more_vert,
                            onTap: () => Modals.showDownloadDetailsBottomModal(context, playlist),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _primary, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.1),
                              offset: const Offset(10, 10),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: _coverFromPlaylist(playlist, songs),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (playlist['type'] == 'SONGS' ? 'SONGS' : (playlist['title'] ?? 'UNTITLED').toString())
                                .toUpperCase(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'OFFLINE ARCHIVE // ${totalHours} HRS',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: _primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              InkWell(
                                onTap: songs.isEmpty ? null : () => GetIt.I<MediaPlayer>().playAll(songs),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: _primary,
                                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 40),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _actionBtn(
                                  icon: Icons.shuffle,
                                  label: 'SHUFFLE',
                                  onTap: songs.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<Map<String, dynamic>>.from(songs);
                                          shuffled.shuffle();
                                          GetIt.I<MediaPlayer>().playAll(shuffled);
                                        },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _actionBtn(
                                  icon: Icons.more_horiz,
                                  label: 'DETAILS',
                                  onTap: () => Modals.showDownloadDetailsBottomModal(context, playlist),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _songRow(
                        context: context,
                        song: song,
                        index: index,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _songRow({
    required BuildContext context,
    required Map<String, dynamic> song,
    required int index,
  }) {
    final media = GetIt.I<MediaPlayer>();

    return ValueListenableBuilder(
      valueListenable: media.currentSongNotifier,
      builder: (context, current, _) {
        final playing = current?.id == song['videoId'];

        return InkWell(
          onTap: () async => media.playSong(song),
          onLongPress: () => Modals.showSongBottomModal(context, song),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
            ),
            child: Row(
              children: [
                if (playing) Container(width: 4, color: _primary),
                SizedBox(
                  width: 44,
                  child: Center(
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: playing ? _primary : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (song['title'] ?? '').toString().toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(song).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: playing ? _primary : Colors.white.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _duration(song),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: playing ? _primary.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await context.read<DownloadPlaylistCubit>().removeSong(song);
                  },
                  icon: Icon(
                    playing ? Icons.equalizer : Icons.delete_outline,
                    color: playing ? _primary : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  static Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFromPlaylist(Map<String, dynamic> playlist, List<Map<String, dynamic>> songs) {
    String? url;

    if (playlist['thumbnails'] is List && (playlist['thumbnails'] as List).isNotEmpty) {
      url = (playlist['thumbnails'] as List).first['url']?.toString();
    }
    if ((url == null || url.isEmpty) && songs.isNotEmpty && songs.first['thumbnails'] is List) {
      final thumbs = songs.first['thumbnails'] as List;
      if (thumbs.isNotEmpty) {
        url = (thumbs.first['url'] ?? '').toString();
      }
    }

    if (url == null || url.isEmpty) {
      return const Center(child: Icon(Icons.music_note, size: 80));
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
      child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
    );
  }

  String _subtitle(Map<String, dynamic> song) {
    final subtitle = song['subtitle']?.toString();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    if (song['artists'] is List) {
      return (song['artists'] as List)
          .map((e) => (e is Map ? e['name'] : null)?.toString())
          .whereType<String>()
          .join(', ');
    }
    return 'Unknown Artist';
  }

  String _duration(Map<String, dynamic> song) {
    if (song['duration'] != null) return song['duration'].toString();
    final s = int.tryParse(song['durationInSeconds']?.toString() ?? '');
    if (s == null) return '--:--';
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}
