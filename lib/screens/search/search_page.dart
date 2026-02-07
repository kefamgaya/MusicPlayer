import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/screens/search/cubit/search_cubit.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.endpoint, this.isMore = false});

  final Map<String, dynamic>? endpoint;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(sl(), endpoint: endpoint),
      child: _SearchPage(title: endpoint?['query']?.toString(), isMore: isMore),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({this.title, this.isMore = false});

  final String? title;
  final bool isMore;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _searchController = TextEditingController(text: widget.title ?? '');
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (widget.title != null && widget.title!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SearchCubit>().search(widget.title!.trim());
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _blink.dispose();
    super.dispose();
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      await context.read<SearchCubit>().fetchNext();
    }
  }

  Future<void> _submit() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    await context.read<SearchCubit>().search(q);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: InternetGuard(
        onConnectivityRestored: () {
          if (_searchController.text.trim().isNotEmpty) {
            context.read<SearchCubit>().search(_searchController.text.trim());
          }
        },
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                _searchInput(),
                Expanded(
                  child: BlocBuilder<SearchCubit, SearchState>(
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is SearchError) {
                        return Center(child: Text(state.message ?? 'Search failed'));
                      }
                      if (state is! SearchSuccess) {
                        return Center(
                          child: Text(
                            'Type and search.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      }

                      final all = _flattenItems(state.sections);
                      final top = _pickTopResult(all);
                      final tracks = all.where((e) => e['videoId'] != null).take(3).toList();
                      final albums = all
                          .where((e) => e['videoId'] == null)
                          .where((e) => _type(e).contains('ALBUM') || _type(e).contains('EP'))
                          .take(4)
                          .toList();

                      return SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (top != null) _topResult(top),
                            if (tracks.isNotEmpty) _tracksSection(tracks),
                            if (albums.isNotEmpty) _albumsSection(albums),
                            if (state.loadingMore)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                          ],
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

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2)),
      ),
      child: Row(
        children: [
          _iconBtn(icon: Icons.arrow_back, onTap: () => context.pop()),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'SEARCH',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _iconBtn(
            icon: Icons.close,
            onTap: () {
              _searchController.clear();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _searchInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search, color: _primary),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'SEARCH...',
                ),
              ),
            ),
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(_blink),
              child: Container(width: 10, height: 20, color: _primary),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _topResult(Map item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TOP RESULT'),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _openItem(item),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(border: Border.all(color: _primary.withValues(alpha: 0.4), width: 2)),
                    clipBehavior: Clip.hardEdge,
                    child: _cover(item, grayscale: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(item).toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 0.9,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _subtitle(item).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            color: _primary,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                          child: const Text(
                            'FOLLOW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tracksSection(List<Map> tracks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TRACKS'),
          const SizedBox(height: 10),
          ...tracks.indexed.map((entry) {
            final i = entry.$1;
            final item = entry.$2;
            final playing = i == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: () => _openItem(item),
                onLongPress: () => Modals.showSongBottomModal(context, item),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border(
                      left: BorderSide(color: playing ? _primary : Colors.white.withValues(alpha: 0.1), width: playing ? 4 : 2),
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(playing ? Icons.equalizer : Icons.play_arrow,
                          color: playing ? _primary : Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title(item).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: playing ? _primary : Colors.white,
                              ),
                            ),
                            Text(
                              _subtitle(item).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: playing ? _primary : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _duration(item),
                        style: TextStyle(
                          fontSize: 11,
                          color: playing ? _primary : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _albumsSection(List<Map> albums) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ALBUMS'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 188,
            ),
            itemBuilder: (_, i) {
              final item = albums[i];
              return InkWell(
                onTap: () => _openItem(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                        ),
                        child: _cover(item, grayscale: true),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _title(item).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _type(item),
                      style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4)),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceMono(
        fontSize: 11,
        letterSpacing: 2.8,
        color: Colors.white.withValues(alpha: 0.4),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  List<Map> _flattenItems(List sections) {
    final out = <Map>[];
    for (final s in sections) {
      if (s is! Map) continue;
      final contents = s['contents'];
      if (contents is List) {
        for (final c in contents) {
          if (c is Map) out.add(c);
        }
      }
    }
    return out;
  }

  Map? _pickTopResult(List<Map> all) {
    for (final item in all) {
      final type = _type(item);
      if (type.contains('ARTIST') || type.contains('PROFILE')) return item;
    }
    return all.isEmpty ? null : all.first;
  }

  Future<void> _openItem(Map item) async {
    if (item['videoId'] != null) {
      await GetIt.I<MediaPlayer>().playSong(Map<String, dynamic>.from(item));
      return;
    }
    if (item['endpoint'] != null) {
      context.push('/browse', extra: {'endpoint': item['endpoint']});
    }
  }

  Widget _cover(Map item, {bool grayscale = false}) {
    final thumbs = (item['thumbnails'] as List?) ?? const [];
    if (thumbs.isEmpty) return const ColoredBox(color: Color(0x22000000));
    final url = (thumbs.first['url'] ?? '').toString();
    if (url.isEmpty) return const ColoredBox(color: Color(0x22000000));
    final child = CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    if (!grayscale) return child;
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
      child: child,
    );
  }

  String _title(Map item) => (item['title'] ?? 'Unknown').toString();

  String _subtitle(Map item) {
    final s = item['subtitle']?.toString();
    if (s != null && s.isNotEmpty) return s;
    if (item['artists'] is List) {
      final names = (item['artists'] as List)
          .map((e) => (e is Map ? e['name'] : null)?.toString())
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) return names;
    }
    return _type(item);
  }

  String _type(Map item) => (item['type'] ?? 'RESULT').toString().toUpperCase();

  String _duration(Map item) {
    if (item['duration'] != null) return item['duration'].toString();
    final sec = int.tryParse(item['durationInSeconds']?.toString() ?? '');
    if (sec == null) return '--:--';
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
