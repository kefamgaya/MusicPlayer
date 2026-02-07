import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:provider/provider.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = GetIt.I<MediaPlayer>();

    return StreamBuilder(
      stream: mediaPlayer.currentTrackStream,
      builder: (context, snapshot) {
        final currentSong = snapshot.data?.currentItem;
        if (currentSong == null) return const SizedBox.shrink();

        return Container(
          color: Colors.white.withValues(alpha: 0.05),
          child: GestureDetector(
            onTap: () => context.push('/player'),
            child: SafeArea(
              top: false,
              child: Dismissible(
                key: Key('bottomplayer${currentSong.id}'),
                direction: DismissDirection.down,
                confirmDismiss: (direction) async {
                  await GetIt.I<MediaPlayer>().stop();
                  return true;
                },
                child: Dismissible(
                  key: Key(currentSong.id),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await GetIt.I<MediaPlayer>().player.seekToPrevious();
                    } else {
                      await GetIt.I<MediaPlayer>().player.seekToNext();
                    }
                    return false;
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: _primary, width: 4),
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SongThumbnail(
                          song: currentSong.extras!,
                          dp: MediaQuery.of(context).devicePixelRatio,
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                (currentSong.artist ?? currentSong.extras?['subtitle'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: GetIt.I<MediaPlayer>().buttonState,
                          builder: (context, buttonState, child) {
                            if (buttonState == ButtonState.loading) {
                              return const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return IconButton(
                              onPressed: () {
                                GetIt.I<MediaPlayer>().player.playing
                                    ? GetIt.I<MediaPlayer>().player.pause()
                                    : GetIt.I<MediaPlayer>().player.play();
                              },
                              style: IconButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                              ),
                              icon: Icon(
                                buttonState == ButtonState.playing ? Icons.pause : Icons.play_arrow,
                                color: _primary,
                              ),
                            );
                          },
                        ),
                        StreamBuilder(
                          stream: context.watch<MediaPlayer>().player.sequenceStateStream,
                          builder: (context, snapshot) {
                            if (!context.watch<MediaPlayer>().player.hasNext) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              onPressed: () => GetIt.I<MediaPlayer>().player.seekToNext(),
                              style: IconButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                              ),
                              icon: const Icon(Icons.skip_next, color: _primary),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
