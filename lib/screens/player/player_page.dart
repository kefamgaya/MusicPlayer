import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/player/widgets/queue_list.dart';
import 'package:gyawun/screens/player/widgets/lyrics_box.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:yt_music/ytmusic.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, this.videoId});
  final String? videoId;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static const Color _primary = Color(0xFF10B748);
  static const Color _bg = Color(0xFF08100A);

  MediaItem? _currentSong;
  bool _showLyrics = false;
  bool _fetchedSong = false;
  Color _accent = _primary;

  @override
  void initState() {
    super.initState();
    if (widget.videoId != null) {
      GetIt.I<YTMusic>().getSongDetails(widget.videoId!).then((song) {
        if (song != null && mounted) {
          GetIt.I<MediaPlayer>().playSong(song);
          setState(() => _fetchedSong = true);
        }
      });
    }
    _currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
    GetIt.I<MediaPlayer>().currentSongNotifier.addListener(_songListener);
  }

  @override
  void dispose() {
    GetIt.I<MediaPlayer>().currentSongNotifier.removeListener(_songListener);
    super.dispose();
  }

  void _songListener() {
    if (!mounted) return;
    setState(() {
      _currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
    });
  }

  Future<void> _updateBackgroundColor(ImageProvider image) async {
    final c = await ColorScheme.fromImageProvider(provider: image);
    if (mounted) {
      setState(() => _accent = c.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId != null && !_fetchedSong) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bg, const Color(0xFF0D150F), Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -80,
                child: _LightLeak(color: _accent.withValues(alpha: 0.2), size: 340),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.45,
                left: -120,
                child: _LightLeak(color: _accent.withValues(alpha: 0.12), size: 300),
              ),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _showLyrics
                      ? _LyricsView(
                          key: const ValueKey('lyrics'),
                          song: _currentSong,
                          accent: _accent,
                          onClose: () => setState(() => _showLyrics = false),
                        )
                      : _NowPlayingView(
                          key: const ValueKey('player'),
                          song: _currentSong,
                          accent: _accent,
                          onBack: () => context.pop(),
                          onOpenLyrics: () => setState(() => _showLyrics = true),
                          onOpenQueue: _openQueue,
                          onImageReady: _updateBackgroundColor,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQueue() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (_) => const SizedBox(height: 520, child: QueueList()),
    );
  }
}

class _NowPlayingView extends StatelessWidget {
  const _NowPlayingView({
    super.key,
    required this.song,
    required this.accent,
    required this.onBack,
    required this.onOpenLyrics,
    required this.onOpenQueue,
    required this.onImageReady,
  });

  final MediaItem? song;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback onOpenLyrics;
  final VoidCallback onOpenQueue;
  final void Function(ImageProvider image) onImageReady;

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = context.watch<MediaPlayer>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -350) {
          onOpenQueue();
        }
      },
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _squareIcon(icon: Icons.arrow_back, onTap: onBack),
              Expanded(
                child: Center(
                  child: Text(
                    'SYSTEM PLAYBACK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
              ),
              _squareIcon(icon: Icons.lyrics, onTap: onOpenLyrics),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B748), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B748).withValues(alpha: 0.3),
                      offset: const Offset(10, 10),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: song == null
                    ? const Center(child: Icon(Icons.music_note, size: 100))
                    : SongThumbnail(song: song!.extras!, onImageReady: onImageReady),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextScroll(
                (song?.title ?? 'Unknown').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
                mode: TextScrollMode.endless,
              ),
              const SizedBox(height: 4),
              Text(
                (song?.artist ?? song?.album ?? song?.extras?['subtitle'] ?? 'No Artist')
                    .toString()
                    .toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _ActionStrip(song: song, accent: accent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'SWIPE UP FOR QUEUE',
          style: TextStyle(
            color: accent.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _ControlPanel(accent: accent, mediaPlayer: mediaPlayer),
        Container(height: 1, margin: const EdgeInsets.fromLTRB(48, 0, 48, 16), color: accent.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _squareIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  const _LyricsView({
    super.key,
    required this.song,
    required this.accent,
    required this.onClose,
  });

  final MediaItem? song;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = context.watch<MediaPlayer>();

    if (song == null) {
      return const Center(child: Text('No song playing'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${song!.title} - ${song!.artist ?? ''}'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                InkWell(onTap: onClose, child: const Icon(Icons.close)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
              ),
              child: LyricsBox(
                currentSong: song!,
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height * 0.56,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _BottomTransport(accent: accent, mediaPlayer: mediaPlayer),
        ],
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.song, required this.accent});

  final MediaItem? song;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final extras = Map<String, dynamic>.from(song?.extras ?? const {});
    final songId = extras['videoId']?.toString() ?? song?.id;

    return Row(
      children: [
        ValueListenableBuilder(
          valueListenable: Hive.box('FAVOURITES').listenable(),
          builder: (context, box, _) {
            final liked = songId != null && box.containsKey(songId);
            return _btn(
              icon: liked ? Icons.favorite : Icons.favorite_border,
              label: 'LIKE',
              accent: accent,
              onTap: songId == null
                  ? null
                  : () async {
                      if (liked) {
                        await box.delete(songId);
                      } else {
                        await box.put(songId, {
                          ...extras,
                          'videoId': songId,
                          'title': song?.title,
                          'subtitle': song?.artist ?? song?.extras?['subtitle'],
                          'createdAt': DateTime.now().millisecondsSinceEpoch,
                        });
                      }
                    },
            );
          },
        ),
        const SizedBox(width: 8),
        _btn(
          icon: Icons.download,
          label: 'SAVE',
          accent: accent,
          onTap: extras.isEmpty
              ? null
              : () async {
                  await GetIt.I<DownloadManager>().downloadSong(extras);
                },
        ),
        const SizedBox(width: 8),
        _btn(
          icon: Icons.more_horiz,
          label: 'MORE',
          accent: accent,
          onTap: extras.isEmpty ? null : () => Modals.showSongBottomModal(context, extras),
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.accent, required this.mediaPlayer});

  final Color accent;
  final MediaPlayer mediaPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _Bar(h: 40),
                  _Bar(h: 78),
                  _Bar(h: 55),
                  _Bar(h: 102),
                  _Bar(h: 65),
                  _Bar(h: 48),
                  _Bar(h: 88),
                ],
              ),
            ),
          ),
          Column(
            children: [
              ValueListenableBuilder(
                valueListenable: mediaPlayer.progressBarState,
                builder: (context, ProgressBarState value, _) {
                  final total = value.total.inMilliseconds <= 0 ? 1 : value.total.inMilliseconds;
                  final pct = (value.current.inMilliseconds / total).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtHms(value.current), style: TextStyle(color: accent.withValues(alpha: 0.85), fontSize: 10)),
                          Text(_fmtHms(value.total), style: TextStyle(color: accent.withValues(alpha: 0.85), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (d) {
                          final box = context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local = box.globalToLocal(d.globalPosition);
                          final p = (local.dx / box.size.width).clamp(0.0, 1.0);
                          mediaPlayer.player.seek(value.total * p);
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(height: 16, color: Colors.white.withValues(alpha: 0.1)),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(height: 16, color: accent),
                            ),
                            Positioned(
                              left: max(0, (pct * MediaQuery.of(context).size.width) - 30),
                              top: -5,
                              child: Container(
                                width: 16,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: accent, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _BottomTransport(accent: accent, mediaPlayer: mediaPlayer),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _BottomTransport extends StatelessWidget {
  const _BottomTransport({required this.accent, required this.mediaPlayer});

  final Color accent;
  final MediaPlayer mediaPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _smallBtn(
          icon: Icons.shuffle,
          selected: mediaPlayer.shuffleModeEnabled,
          onTap: () async {
            await mediaPlayer.player.setShuffleModeEnabled(
              !mediaPlayer.shuffleModeEnabled,
            );
          },
        ),
        Row(
          children: [
            _rectBtn(
              icon: Icons.skip_previous,
              onTap: () {
                mediaPlayer.player.seekToPrevious();
              },
            ),
            const SizedBox(width: 14),
            ValueListenableBuilder(
              valueListenable: mediaPlayer.buttonState,
              builder: (context, ButtonState state, _) {
                final isPlaying = state == ButtonState.playing;
                return InkWell(
                  onTap: () => isPlaying ? mediaPlayer.player.pause() : mediaPlayer.player.play(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B748), Color(0xFF0A6E2B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            _rectBtn(
              icon: Icons.skip_next,
              onTap: () {
                mediaPlayer.player.seekToNext();
              },
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: mediaPlayer.loopMode,
          builder: (context, LoopMode loop, _) {
            final active = loop != LoopMode.off;
            return _smallBtn(
              icon: loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
              selected: active,
              onTap: mediaPlayer.changeLoopMode,
            );
          },
        ),
      ],
    );
  }

  Widget _smallBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          color: selected ? accent.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _rectBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}

class _LightLeak extends StatelessWidget {
  const _LightLeak({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 12,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.h});

  final double h;

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: h, color: const Color(0xFF10B748));
  }
}
