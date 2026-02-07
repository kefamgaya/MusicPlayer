import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/playlist_details_cubit.dart';

class PlaylistDetailsPage extends StatelessWidget {
  const PlaylistDetailsPage({super.key, required this.playlistkey});

  final String playlistkey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaylistDetailsCubit(playlistkey)..load(),
      child: _PlaylistDetailsView(playlistKey: playlistkey),
    );
  }
}

class _PlaylistDetailsView extends StatelessWidget {
  const _PlaylistDetailsView({required this.playlistKey});

  final String playlistKey;

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
        body: Stack(
          children: [
            Positioned.fill(child: _LightLeak()),
            BlocBuilder<PlaylistDetailsCubit, PlaylistDetailsState>(
              builder: (context, state) {
                return switch (state) {
                  PlaylistDetailsLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  PlaylistDetailsError(:final message) => Center(
                    child: Text(message),
                  ),
                  PlaylistDetailsLoaded(:final playlist) => _PlaylistBody(
                    playlistKey: playlistKey,
                    playlist: Map<String, dynamic>.from(playlist),
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistBody extends StatelessWidget {
  const _PlaylistBody({required this.playlistKey, required this.playlist});

  final String playlistKey;
  final Map<String, dynamic> playlist;

  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final songs = (playlist['songs'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    final cover = _coverFromPlaylist(playlist, songs);
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
                    'COLLECTION // ${playlistKey.substring(((playlistKey.length - 3).clamp(0, playlistKey.length)) as int)}',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: _primary,
                      letterSpacing: 2,
                    ),
                  ),
                  _iconBtn(icon: Icons.more_vert, onTap: () {}),
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
                  child: cover == null
                      ? const Center(child: Icon(Icons.music_note, size: 80))
                      : CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover),
                ),
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
                    (playlist['title'] ?? 'Untitled').toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CURATED BY SYSTEM_ADMIN // ${totalHours} HRS',
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
                        onTap: songs.isEmpty
                            ? null
                            : () => GetIt.I<MediaPlayer>().playAll(songs),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: _primary,
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.favorite,
                          label: 'LIKE',
                          onTap: songs.isEmpty
                              ? null
                              : () async {
                                  final box = Hive.box('FAVOURITES');
                                  for (final s in songs) {
                                    final id = s['videoId'];
                                    if (id == null || box.containsKey(id)) continue;
                                    await box.put(id, {
                                      ...s,
                                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                                    });
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Added to favourites')),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.download,
                          label: 'SAVE',
                          onTap: songs.isEmpty
                              ? null
                              : () async {
                                  final dm = GetIt.I<DownloadManager>();
                                  for (final s in songs) {
                                    await dm.downloadSong(s);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Download queued')),
                                    );
                                  }
                                },
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
              child: _trackRow(
                context: context,
                playlistKey: playlistKey,
                song: song,
                index: index,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }

  Widget _trackRow({
    required BuildContext context,
    required String playlistKey,
    required Map<String, dynamic> song,
    required int index,
  }) {
    final media = GetIt.I<MediaPlayer>();

    return ValueListenableBuilder<MediaItem?>(
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
                            color: playing
                                ? _primary
                                : Colors.white.withValues(alpha: 0.4),
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
                      color: playing
                          ? _primary.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final msg = await context.read<PlaylistDetailsCubit>().removeSong(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  icon: Icon(
                    playing ? Icons.equalizer : Icons.more_horiz,
                    color: playing
                        ? _primary
                        : Colors.white.withValues(alpha: 0.25),
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
    required Future<void> Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap == null ? null : () async => onTap(),
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

  String? _coverFromPlaylist(Map<String, dynamic> playlist, List<Map<String, dynamic>> songs) {
    if (playlist['thumbnails'] is List && (playlist['thumbnails'] as List).isNotEmpty) {
      return (playlist['thumbnails'] as List).first['url']?.toString();
    }
    if (songs.isNotEmpty && songs.first['thumbnails'] is List && (songs.first['thumbnails'] as List).isNotEmpty) {
      return (songs.first['thumbnails'] as List).first['url']?.toString();
    }
    return null;
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

class _LightLeak extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.8),
          radius: 1.1,
          colors: [Color(0x1410B981), Color(0x00000000)],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9, 0.8),
            radius: 0.7,
            colors: [Color(0x10FFFFFF), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}
