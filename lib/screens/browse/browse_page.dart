import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/screens/browse/cubit/browse_cubit.dart';
import 'package:gyawun/services/media_player.dart';

class BrowsePage extends StatelessWidget {
  final Map<String, dynamic> endpoint;
  final bool isMore;

  const BrowsePage({super.key, required this.endpoint, this.isMore = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BrowseCubit(sl(), endpoint: endpoint)..fetch(),
      child: _BrowsePage(isMore: isMore),
    );
  }
}

class _BrowsePage extends StatefulWidget {
  const _BrowsePage({required this.isMore});

  final bool isMore;

  @override
  State<_BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<_BrowsePage> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      await context.read<BrowseCubit>().fetchNext();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayTheme = GoogleFonts.spaceGroteskTextTheme(
      Theme.of(context).textTheme,
    );
    final mono = GoogleFonts.spaceMono();

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: displayTheme,
      ),
      child: InternetGuard(
        onConnectivityRestored: context.read<BrowseCubit>().fetch,
        child: Scaffold(
          backgroundColor: _bg,
          body: BlocBuilder<BrowseCubit, BrowseState>(
            builder: (context, state) {
              if (state is BrowseLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BrowseError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.message ?? 'Failed to load artist page'),
                  ),
                );
              }

              final data = state as BrowseSuccess;
              final artist = _ArtistProfileData.fromState(data);

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              artist.heroImage.isEmpty
                                  ? Container(color: Colors.white.withValues(alpha: 0.05))
                                  : Image.network(artist.heroImage, fit: BoxFit.cover),
                              Container(color: Colors.white.withValues(alpha: 0.1)),
                              Positioned(
                                top: 56,
                                left: 16,
                                right: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _glassIconButton(
                                      icon: Icons.arrow_back,
                                      onPressed: () => context.pop(),
                                    ),
                                    _glassIconButton(
                                      icon: Icons.more_vert,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artist.metaLine,
                                      style: mono.copyWith(
                                        fontSize: 11,
                                        color: _primary,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      artist.displayName,
                                      style: displayTheme.displayLarge?.copyWith(
                                        fontSize: 62,
                                        height: 0.85,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -2,
                                        shadows: const [
                                          Shadow(
                                            color: Color.fromRGBO(0, 0, 0, 0.5),
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _actionButton(
                                  label: 'FOLLOW',
                                  filled: true,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _actionButton(
                                  label: 'PLAY',
                                  onTap: () => _playFirst(artist.tracks),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _actionButton(
                                  label: 'RADIO',
                                  onTap: () => _playFirst(artist.tracks),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _titleRow(
                          left: 'POPULAR TRACKS',
                          right: artist.tracks.length > 4 ? 'View All' : '',
                          rightColor: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        ...artist.tracks.take(4).toList().indexed.map((entry) {
                          final i = entry.$1;
                          final track = entry.$2;
                          return _trackTile(
                            index: i + 1,
                            track: track,
                            mono: mono,
                            displayTheme: displayTheme,
                          );
                        }),
                        const SizedBox(height: 34),
                        _titleRow(
                          left: 'DISCOGRAPHY',
                          right: 'ALBUMS',
                          rightColor: _primary,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 215,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: artist.albums.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 16),
                            itemBuilder: (_, index) {
                              final album = artist.albums[index];
                              return _albumCard(
                                album: album,
                                mono: mono,
                                display: displayTheme,
                                onTap: () {
                                  if (album['endpoint'] != null) {
                                    context.push(
                                      '/browse',
                                      extra: {'endpoint': album['endpoint']},
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        if (data.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _playFirst(List<Map> tracks) async {
    if (tracks.isEmpty) return;
    await GetIt.I<MediaPlayer>().playSong(Map.from(tracks.first));
  }

  Widget _trackTile({
    required int index,
    required Map track,
    required TextStyle mono,
    required TextTheme displayTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: () async => GetIt.I<MediaPlayer>().playSong(Map.from(track)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: mono.copyWith(fontSize: 12, color: _primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (track['title'] ?? '').toString().toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: displayTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      ((track['subtitle'] ?? track['artists']
                                  ?.map((a) => a['name'])
                                  .join(', ')) ??
                              '')
                          .toString()
                          .toUpperCase(),
                      style: mono.copyWith(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                (track['duration'] ?? '--:--').toString(),
                style: mono.copyWith(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.play_arrow, color: Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  static Widget _actionButton({
    required String label,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? _primary : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: filled ? _primary : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: filled ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  static Widget _titleRow({
    required String left,
    required String right,
    required Color rightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _primary, width: 4)),
            ),
            child: Text(
              left,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                fontSize: 24,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Text(
            right,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: rightColor,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _albumCard({
    required Map album,
    required TextStyle mono,
    required TextTheme display,
    required VoidCallback onTap,
  }) {
    final thumbs = (album['thumbnails'] as List?) ?? const [];
    final image = thumbs.isNotEmpty
        ? (thumbs.last['url'] ?? thumbs.first['url'] ?? '').toString()
        : '';
    final year = (album['year'] ?? album['subtitle'] ?? '').toString();

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
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
                child: image.isEmpty
                    ? const SizedBox.shrink()
                    : Image.network(image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (album['title'] ?? '').toString().toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: display.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              year,
              style: mono.copyWith(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistProfileData {
  final String displayName;
  final String metaLine;
  final String heroImage;
  final List<Map> tracks;
  final List<Map> albums;

  const _ArtistProfileData({
    required this.displayName,
    required this.metaLine,
    required this.heroImage,
    required this.tracks,
    required this.albums,
  });

  factory _ArtistProfileData.fromState(BrowseSuccess state) {
    final header = state.header;
    final title = (header['title'] ?? 'Unknown Artist').toString();
    final subtitle = (header['subtitle'] ?? header['secondSubtitle'] ?? '').toString();
    final thumbs = (header['thumbnails'] as List?) ?? const [];
    final heroImage = thumbs.isNotEmpty
        ? (thumbs.last['url'] ?? thumbs.first['url'] ?? '').toString()
        : '';

    final items = <Map>[];
    for (final section in state.sections) {
      if (section is! Map) continue;
      final contents = section['contents'];
      if (contents is List) {
        for (final c in contents) {
          if (c is Map) items.add(c);
        }
      }
    }

    final tracks = items.where((e) => e['videoId'] != null).toList();
    final albums = items
        .where((e) => e['videoId'] == null && e['thumbnails'] is List)
        .where((e) => (e['type']?.toString().toUpperCase().contains('ALBUM') ?? true))
        .toList();

    return _ArtistProfileData(
      displayName: title.toUpperCase().replaceAll(' ', '\n'),
      metaLine: subtitle.isEmpty
          ? 'VERIFIED ARTIST // LIVE PROFILE'
          : 'VERIFIED ARTIST // ${subtitle.toUpperCase()}',
      heroImage: heroImage,
      tracks: tracks,
      albums: albums,
    );
  }
}
