import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import 'cubit/favourites_cubit.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavouritesCubit()..load(),
      child: const _FavouritesView(),
    );
  }
}

class _FavouritesView extends StatefulWidget {
  const _FavouritesView();

  @override
  State<_FavouritesView> createState() => _FavouritesViewState();
}

class _FavouritesViewState extends State<_FavouritesView> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);
    final mono = GoogleFonts.spaceMono();

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: InternetGuard(
        child: Scaffold(
          backgroundColor: _bg,
          floatingActionButton: BlocBuilder<FavouritesCubit, FavouritesState>(
            builder: (context, state) {
              if (state is! FavouritesLoaded || state.songs.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(),
                  onPressed: () {
                    final shuffled = List<Map>.from(state.songs);
                    shuffled.shuffle();
                    GetIt.I<MediaPlayer>().playAll(shuffled);
                  },
                  child: const Icon(Icons.shuffle),
                ),
              );
            },
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'FAVOURITES',
                      style: textTheme.displaySmall?.copyWith(
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Icon(Icons.search, color: _primary),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _query = v.trim()),
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'FILTER LIKED SONGS...',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BlocBuilder<FavouritesCubit, FavouritesState>(
                builder: (context, state) {
                  if (state is FavouritesLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is FavouritesError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(state.message)),
                    );
                  }

                  final songs = (state as FavouritesLoaded)
                      .songs
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  final filtered = songs.where((song) {
                    if (_query.isEmpty) return true;
                    final title = (song['title'] ?? '').toString().toLowerCase();
                    final subtitle = _subtitle(song).toLowerCase();
                    final q = _query.toLowerCase();
                    return title.contains(q) || subtitle.contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _query.isEmpty ? 'No liked songs yet.' : 'No matches found.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final song = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: InkWell(
                          onTap: () async {
                            await GetIt.I<MediaPlayer>().playSong(Map.from(song));
                          },
                          onLongPress: () => Modals.showSongBottomModal(context, song),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: _cover(song),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (song['title'] ?? '').toString().toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _subtitle(song).toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            _duration(song),
                                            style: mono.copyWith(
                                              fontSize: 9,
                                              color: _primary.withValues(alpha: 0.85),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              'LIKED ON: ${_likedOn(song)}',
                                              overflow: TextOverflow.ellipsis,
                                              style: mono.copyWith(
                                                fontSize: 9,
                                                color: _primary.withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await context
                                        .read<FavouritesCubit>()
                                        .remove(song['id'] ?? song['videoId']);
                                  },
                                  icon: Icon(
                                    Icons.favorite,
                                    color: _primary,
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
              const SliverToBoxAdapter(child: SizedBox(height: 84)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover(Map<String, dynamic> song) {
    final thumbs = (song['thumbnails'] as List?) ?? const [];
    if (thumbs.isEmpty) {
      return const Icon(Icons.music_note);
    }
    final url = (thumbs.first['url'] ?? '').toString();
    if (url.isEmpty) {
      return const Icon(Icons.music_note);
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

  String _likedOn(Map<String, dynamic> song) {
    final created = song['createdAt'];
    if (created is int) {
      return DateFormat('dd.MM.yy').format(
        DateTime.fromMillisecondsSinceEpoch(created),
      );
    }
    return '--.--.--';
  }
}
