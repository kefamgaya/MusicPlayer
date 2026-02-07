import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/screens/library/cubit/library_cubit.dart';
import 'package:gyawun/services/library.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(sl<LibraryService>())..loadLibrary(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);
    const bg = Color(0xFF0A0A0A);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: bg,
        textTheme: textTheme,
      ),
      child: InternetGuard(
        child: Scaffold(
          backgroundColor: bg,
          body: BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              return switch (state) {
                LibraryLoading() => const Center(child: CircularProgressIndicator()),
                LibraryError(:final message) => Center(child: Text(message)),
                LibraryLoaded(
                  :final playlists,
                  :final favouritesCount,
                  :final downloadsCount,
                  :final historyCount,
                ) => _LibraryBody(
                  playlists: playlists,
                  favouritesCount: favouritesCount,
                  downloadsCount: downloadsCount,
                  historyCount: historyCount,
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _LibraryBody extends StatefulWidget {
  const _LibraryBody({
    required this.playlists,
    required this.favouritesCount,
    required this.downloadsCount,
    required this.historyCount,
  });

  final Map playlists;
  final int favouritesCount;
  final int downloadsCount;
  final int historyCount;

  @override
  State<_LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends State<_LibraryBody> {
  static const Color _primary = Color(0xFF10B981);

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final all = widget.playlists.entries
        .where((e) => e.value is Map)
        .map((e) => _LibraryItem.fromEntry(e.key.toString(), Map.from(e.value)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final playlists = all.where((e) => !e.isArtist && !e.isAlbum).toList();
    final artists = all.where((e) => e.isArtist).toList();
    final albums = all.where((e) => e.isAlbum).toList();

    final visible = switch (_tabIndex) {
      1 => artists,
      2 => albums,
      _ => playlists,
    };

    final selectedLabel = switch (_tabIndex) {
      1 => 'ARTISTS',
      2 => 'ALBUMS',
      _ => 'PLAYLISTS',
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
              ),
              child: Text(
                'LIBRARY',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: Row(
                children: [
                  _tabButton('PLAYLISTS', 0),
                  _tabButton('ARTISTS', 1),
                  _tabButton('ALBUMS', 2),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _favouritesCard(),
                const SizedBox(height: 12),
                _smallHubCard(
                  icon: Icons.cloud_download,
                  title: 'DOWNLOADS',
                  value: widget.downloadsCount,
                  onTap: () => context.push('/library/downloads'),
                ),
                const SizedBox(height: 12),
                _smallHubCard(
                  icon: Icons.history,
                  title: 'HISTORY',
                  value: widget.historyCount,
                  onTap: () => context.push('/library/history'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: _primary, width: 4)),
                  ),
                  child: Text(
                    'RECENTLY ADDED',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'SORT: DATE_DESC',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No $selectedLabel yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final item = visible[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _libraryItemTile(item: item),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            border: Border(
              left: index == 0
                  ? BorderSide.none
                  : BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _favouritesCard() {
    return InkWell(
      onTap: () => context.push('/library/favourites'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              color: _primary,
              child: const Icon(Icons.favorite, color: Colors.black, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAVORITE TRACKS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.favouritesCount} ITEMS // ARCHIVED',
                    style: GoogleFonts.spaceMono(
                      color: _primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _smallHubCard({
    required IconData icon,
    required String title,
    required int value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$value',
              style: GoogleFonts.spaceMono(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryItemTile({required _LibraryItem item}) {
    return InkWell(
      onTap: () {
        if (item.isPredefined && item.endpoint != null) {
          context.push('/browse', extra: {'endpoint': item.endpoint});
        } else {
          context.push('/library/playlist_details', extra: {'playlistkey': item.key});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: item.imageUrl == null
                  ? Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.queue_music),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.metaLine,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ADDED: ${DateFormat('MM.dd.yyyy').format(item.createdAtDate)}',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  final String key;
  final String title;
  final String? imageUrl;
  final String type;
  final bool isPredefined;
  final int tracks;
  final int createdAt;
  final Map<String, dynamic>? endpoint;

  const _LibraryItem({
    required this.key,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.isPredefined,
    required this.tracks,
    required this.createdAt,
    required this.endpoint,
  });

  factory _LibraryItem.fromEntry(String key, Map item) {
    final thumbnails = item['thumbnails'] as List?;
    final image = thumbnails != null && thumbnails.isNotEmpty
        ? (thumbnails.first['url'] ?? thumbnails.last['url'])?.toString()
        : null;

    final songCount = item['songs'] is List
        ? (item['songs'] as List).length
        : (item['trackCount'] as int? ?? 0);

    return _LibraryItem(
      key: key,
      title: (item['title'] ?? 'Untitled').toString(),
      imageUrl: image,
      type: (item['type'] ?? 'PLAYLIST').toString().toUpperCase(),
      isPredefined: item['isPredefined'] == true,
      tracks: songCount,
      createdAt: (item['createdAt'] as int?) ?? 0,
      endpoint: item['endpoint'] is Map
          ? Map<String, dynamic>.from(item['endpoint'] as Map)
          : null,
    );
  }

  bool get isArtist => type.contains('ARTIST');

  bool get isAlbum => type.contains('ALBUM');

  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt == 0 ? DateTime.now().millisecondsSinceEpoch : createdAt);

  String get metaLine {
    final kind = isArtist
        ? 'ARTIST'
        : isAlbum
            ? 'ALBUM'
            : 'PLAYLIST';
    final suffix = tracks == 1 ? '1 TRACK' : '$tracks TRACKS';
    return '$kind // $suffix';
  }
}
