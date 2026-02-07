import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/widgets/section_item.dart';
import 'package:gyawun/screens/home/cubit/home_cubit.dart';
import 'package:gyawun/services/media_player.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(sl())..fetch(),
      child: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B748);

  late final AnimationController _pulseController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.55,
      upperBound: 1,
    )..repeat(reverse: true);
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      await context.read<HomeCubit>().fetchNext();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      Theme.of(context).textTheme,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: InternetGuard(
        onConnectivityRestored: context.read<HomeCubit>().fetch,
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(textTheme: textTheme),
                Expanded(
                  child: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is HomeError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              state.message ?? 'Failed to load home feed',
                            ),
                          ),
                        );
                      }

                      final data = state as HomeSuccess;
                      final forYou = _extractItems(data.sections, limit: 3);
                      final releases = _extractItems(data.sections, skip: 3, limit: 4);
                      final trending = _extractTrending(data, forYou, releases);
                      final consumed = {...forYou, ...releases}
                          .map((e) => _itemIdentity(e.raw))
                          .whereType<String>()
                          .toSet();
                      final remainingSections = _buildRemainingSections(
                        data.sections,
                        consumed,
                      );

                      return RefreshIndicator(
                        onRefresh: context.read<HomeCubit>().refresh,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SearchBar(
                                textTheme: textTheme,
                                onTap: () => context.go('/search'),
                              ),
                              _ChipsStrip(chips: data.chips),
                              _SectionHeader(textTheme: textTheme),
                              _ForYouCarousel(
                                items: forYou,
                                textTheme: textTheme,
                                onTapItem: (item) => _openItem(context, item.raw),
                              ),
                              _TrendingTicker(
                                items: trending,
                                textTheme: textTheme,
                                pulse: _pulseController,
                              ),
                              _YourMixCard(
                                textTheme: textTheme,
                                onPlay: () {
                                  if (forYou.isNotEmpty) {
                                    _openItem(context, forYou.first.raw);
                                  }
                                },
                              ),
                              _NewReleasesGrid(
                                items: releases,
                                textTheme: textTheme,
                                onTapItem: (item) => _openItem(context, item.raw),
                              ),
                              if (remainingSections.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                                  child: Text(
                                    'MORE FROM FEED',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ...remainingSections.map((s) => SectionItem(section: s)),
                              if (data.loadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _extractTrending(
    HomeSuccess state,
    List<_BrutalItem> forYou,
    List<_BrutalItem> releases,
  ) {
    final fromChips = state.chips
        .map((e) => (e is Map ? e['title'] : null)?.toString())
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .take(4)
        .map((e) => e.trim().toUpperCase().replaceAll(' ', '_'))
        .toList();

    if (fromChips.isNotEmpty) return fromChips;

    final fromItems = [...forYou, ...releases]
        .map((e) => e.title.toUpperCase().replaceAll(' ', '_'))
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(4)
        .toList();

    return fromItems.isEmpty
        ? const ['NEURAL_DANCE.MP3', 'SYSTEM_FAILURE_DUB', 'KRYPTON_CORE_MIX']
        : fromItems;
  }

  List<_BrutalItem> _extractItems(
    List sections, {
    int skip = 0,
    int limit = 4,
  }) {
    final items = <Map>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final contents = section['contents'];
      if (contents is List) {
        for (final c in contents) {
          if (c is Map && c['thumbnails'] is List && (c['title'] ?? '').toString().isNotEmpty) {
            items.add(c);
          }
        }
      }
    }

    return items.skip(skip).take(limit).map(_BrutalItem.fromMap).toList();
  }

  Future<void> _openItem(BuildContext context, Map item) async {
    if (item['endpoint'] != null && item['videoId'] == null) {
      context.push('/browse', extra: {'endpoint': item['endpoint']});
      return;
    }

    if (item['videoId'] != null) {
      await GetIt.I<MediaPlayer>().playSong(Map.from(item));
    }
  }

  List<Map> _buildRemainingSections(List sections, Set<String> consumed) {
    final out = <Map>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final contents = section['contents'];
      if (contents is! List) continue;

      final filtered = contents
          .whereType<Map>()
          .where((item) {
            final id = _itemIdentity(item);
            return id == null || !consumed.contains(id);
          })
          .toList();

      if (filtered.isEmpty) continue;
      out.add({...section, 'contents': filtered});
    }
    return out;
  }

  String? _itemIdentity(Map item) {
    if (item['videoId'] != null) return 'v:${item['videoId']}';
    if (item['playlistId'] != null) return 'p:${item['playlistId']}';
    if (item['endpoint'] is Map) {
      final ep = item['endpoint'] as Map;
      if (ep['browseId'] != null) return 'b:${ep['browseId']}';
      if (ep['watchEndpoint'] != null) return 'w:${ep['watchEndpoint']}';
    }
    final t = (item['title'] ?? '').toString();
    final s = (item['subtitle'] ?? '').toString();
    if (t.isNotEmpty) return 't:$t::$s';
    return null;
  }
}

class _ChipsStrip extends StatelessWidget {
  const _ChipsStrip({required this.chips});

  final List chips;

  @override
  Widget build(BuildContext context) {
    final filtered = chips
        .whereType<Map>()
        .where((c) => (c['title'] ?? '').toString().trim().isNotEmpty)
        .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = filtered[i];
          return InkWell(
            onTap: () {
              if (chip['endpoint'] != null) {
                context.push('/chip', extra: {'title': chip['title'], 'endpoint': chip['endpoint']});
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                (chip['title'] ?? '').toString().toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: _HomePageState._primary,
            alignment: Alignment.center,
            child: const Icon(Icons.menu, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'BRUTALIST BEATS',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
            alignment: Alignment.center,
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.textTheme, required this.onTap});

  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  ),
                ),
                child: Icon(Icons.search, color: _HomePageState._primary),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'SEARCH ARCHIVE...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: _HomePageState._primary, width: 4),
              ),
            ),
            child: Text(
              'FOR YOU',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Text(
            'LIVE FEED',
            style: textTheme.labelSmall?.copyWith(
              color: _HomePageState._primary,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForYouCarousel extends StatelessWidget {
  const _ForYouCarousel({
    required this.items,
    required this.textTheme,
    required this.onTapItem,
  });

  final List<_BrutalItem> items;
  final TextTheme textTheme;
  final void Function(_BrutalItem item) onTapItem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 334,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onTapItem(item),
            child: Container(
              width: 256,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(
                  left: BorderSide(color: _HomePageState._primary, width: 4),
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 224,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 2),
                    ),
                    child: item.image.isEmpty
                        ? const SizedBox.shrink()
                        : Image.network(item.image, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: _HomePageState._primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingTicker extends StatelessWidget {
  const _TrendingTicker({
    required this.items,
    required this.textTheme,
    required this.pulse,
  });

  final List<String> items;
  final TextTheme textTheme;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            Container(
              color: _HomePageState._primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                'TRENDING',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, _) {
                  return Opacity(
                    opacity: pulse.value,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 28),
                      itemBuilder: (_, i) {
                        return Center(
                          child: Text(
                            '■ ${items[i]}',
                            style: textTheme.labelSmall?.copyWith(letterSpacing: 1.4),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourMixCard extends StatelessWidget {
  const _YourMixCard({required this.textTheme, required this.onPlay});

  final TextTheme textTheme;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            top: BorderSide(color: _HomePageState._primary, width: 4),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR MIX',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Curated by Algorithms / Live',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: TextButton(
                onPressed: onPlay,
                style: TextButton.styleFrom(
                  backgroundColor: _HomePageState._primary,
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Icon(Icons.play_arrow, size: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewReleasesGrid extends StatelessWidget {
  const _NewReleasesGrid({
    required this.items,
    required this.textTheme,
    required this.onTapItem,
  });

  final List<_BrutalItem> items;
  final TextTheme textTheme;
  final void Function(_BrutalItem item) onTapItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW RELEASES',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 214,
            ),
            itemBuilder: (_, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onTapItem(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 164,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: item.image.isEmpty
                          ? const SizedBox.shrink()
                          : ColorFiltered(
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
                              child: Image.network(item.image, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 2, color: _HomePageState._primary),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BrutalItem {
  final String title;
  final String meta;
  final String image;
  final Map raw;

  const _BrutalItem({
    required this.title,
    required this.meta,
    required this.image,
    required this.raw,
  });

  factory _BrutalItem.fromMap(Map item) {
    final thumbs = (item['thumbnails'] as List?) ?? const [];
    final image = thumbs.isNotEmpty
        ? (thumbs.last['url'] ?? thumbs.first['url'] ?? '').toString()
        : '';
    final subtitle = item['subtitle']?.toString();
    final artists = item['artists'] is List
        ? (item['artists'] as List)
            .map((a) => (a is Map ? a['name'] : null)?.toString())
            .whereType<String>()
            .join(', ')
        : '';

    final metaSource = subtitle?.isNotEmpty == true ? subtitle! : artists;

    return _BrutalItem(
      title: (item['title'] ?? 'UNKNOWN').toString().toUpperCase(),
      meta: metaSource.toUpperCase(),
      image: image,
      raw: item,
    );
  }
}
