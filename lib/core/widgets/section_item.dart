
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/sections/section_multi_column.dart';
import 'package:gyawun/core/widgets/sections/section_row.dart';
import 'package:yt_music/ytmusic.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/extensions.dart';
import '../../services/media_player.dart';
import '../../utils/bottom_modals.dart';

class SectionItem extends StatefulWidget {
  const SectionItem({required this.section, this.isMore = false, super.key});
  final Map section;
  final bool isMore;

  @override
  State<SectionItem> createState() => _SectionItemState();
}

class _SectionItemState extends State<SectionItem> {
  final ScrollController horizontalScrollController = ScrollController();
  PageController horizontalPageController = PageController();
  bool loadingMore = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    horizontalPageController.dispose();
    horizontalScrollController.dispose();
    super.dispose();
  }

  void loadMoreItems() {
    if (widget.section['continuation'] != null) {
      setState(() {
        loadingMore = true;
      });
      GetIt.I<YTMusic>()
          .getMoreItems(continuation: widget.section['continuation'])
          .then((value) {
            setState(() {
              widget.section['contents'].addAll(value['items']);
              widget.section['continuation'] = value['continuation'];
              loadingMore = false;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    horizontalPageController = PageController(
      viewportFraction: 350 / MediaQuery.of(context).size.width,
    );
    return widget.section['contents'].isEmpty
        ? const SizedBox()
        : Column(
            children: [
              if (widget.section['title'] != null)
                SectionHeader(
                  title: widget.section['title'],
                  trailing: widget.section['trailing'],
                  contents: widget.section['contents'],
                ),
              if (widget.section['viewType'] == 'COLUMN' && !widget.isMore)
                SectionMultiColumn(items: widget.section['contents'])
              else if (widget.section['viewType'] == 'SINGLE_COLUMN' ||
                  widget.isMore)
                SingleColumnList(songs: widget.section['contents'])
              else
                SectionRow(items: widget.section['contents']),
              if (loadingMore) const AdaptiveProgressRing(),
              if (widget.section['continuation'] != null && !loadingMore)
                AdaptiveButton(
                  onPressed: loadMoreItems,
                  child: const Text("Load More"),
                ),
            ],
          );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    required this.contents,
  });
  final String title;
  final Map? trailing;
  final List contents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          if (trailing != null)
            TextButton.icon(
              iconAlignment: IconAlignment.end,
              label: Text(trailing!['text']),
              icon: const Icon(FluentIcons.play_24_filled),

              onPressed: () async {
                if (trailing!['playable'] == false &&
                    trailing!['endpoint'] != null) {
                  context.push(
                    '/browse',
                    extra: {'endpoint': trailing!['endpoint'], 'isMore': true},
                  );
                } else {
                  BottomMessage.showText(
                    context,
                    S.of(context).Songs_Will_Start_Playing_Soon,
                  );
                  if (trailing!['endpoint'] != null) {
                    await GetIt.I<MediaPlayer>().startPlaylistSongs(
                      trailing!['endpoint'],
                    );
                  } else {
                    await GetIt.I<MediaPlayer>().playAll(contents);
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class SingleColumnList extends StatelessWidget {
  const SingleColumnList({required this.songs, super.key});
  final List songs;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: songs.map((song) {
        return SongTile(song: song);
      }).toList(),
    );
  }
}

class SongTile extends StatelessWidget {
  const SongTile({required this.song, this.playlistId, super.key});
  final String? playlistId;
  final Map song;
  @override
  Widget build(BuildContext context) {
    List thumbnails = song['thumbnails'];
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    return AdaptiveListTile(
      onTap: () async {
        if (song['endpoint'] != null && song['videoId'] == null) {
          context.push('/browse', extra: {'endpoint': song['endpoint']});
        } else {
          await GetIt.I<MediaPlayer>().playSong(Map.from(song));

          // final s = GetIt.I<HttpServer>();
          // await get(Uri.parse(
          //     'http://${s.address.host}:${s.port}/stream?videoId=${song['videoId']}'));
        }
      },
      onSecondaryTap: () {
        if (song['videoId'] != null) {
          Modals.showSongBottomModal(context, song);
        }
      },
      onLongPress: () {
        if (song['videoId'] != null) {
          Modals.showSongBottomModal(context, song);
        }
      },
      title: Text(song['title'] ?? "", maxLines: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CachedNetworkImage(
          imageUrl: thumbnails
              .where((el) => el['width'] >= 50)
              .toList()
              .first['url'],
          height: height,
          width: 50,
          fit: BoxFit.cover,
        ),
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (song['explicit'] == true)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                Icons.explicit,
                size: 18,
                color: Colors.grey.withValues(alpha:0.9),
              ),
            ),
          Expanded(
            child: Text(
              _buildSubtitle(song),
              maxLines: 1,
              style: TextStyle(color: Colors.grey.withValues(alpha:0.9)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: song['endpoint'] != null && song['videoId'] == null
          ? Icon(AdaptiveIcons.chevron_right)
          : null,
      description: (song['type'] == 'EPISODE' && song['description'] != null)
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  ExpandableText(
                    song['description'].split('\n')?[0] ?? '',
                    expandText: S.of(context).Show_More,
                    collapseText: S.of(context).Show_Less,
                    maxLines: 3,
                    style: TextStyle(color: context.subtitleColor),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  String _buildSubtitle(Map item) {
    List sub = [];
    if (sub.isEmpty && item['artists'] != null) {
      for (Map artist in item['artists']) {
        sub.add(artist['name']);
      }
    }
    if (sub.isEmpty && item['album'] != null) {
      sub.add(item['album']['name']);
    }
    String s = sub.join(' · ');
    return item['subtitle'] ?? s;
  }
}
