import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/screens/chip/cubit/chip_cubit.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

class ChipPage extends StatelessWidget {
  const ChipPage({super.key, required this.title, required this.endpoint});

  final String title;
  final Map<String, dynamic> endpoint;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChipCubit(sl(), endpoint: endpoint)..fetch(),
      child: _ChipPage(title: title),
    );
  }
}

class _ChipPage extends StatefulWidget {
  const _ChipPage({required this.title});

  final String title;

  @override
  State<_ChipPage> createState() => _ChipPageState();
}

class _ChipPageState extends State<_ChipPage> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollListener() async {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80) {
      await context.read<ChipCubit>().fetchNext();
    }
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
        onConnectivityRestored: context.read<ChipCubit>().fetch,
        child: Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: BlocBuilder<ChipCubit, ChipState>(
                    builder: (context, state) {
                      if (state is ChipLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ChipError) {
                        return Center(child: Text(state.message ?? 'Error'));
                      }

                      final data = state as ChipSuccess;
                      final items = _flattenItems(data.sections);

                      return RefreshIndicator(
                        onRefresh: context.read<ChipCubit>().refresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          itemCount: items.length + (data.loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final item = items[index];
                            final highlight = index == 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _openItem(context, item),
                                onLongPress: () {
                                  if (item['videoId'] != null) {
                                    Modals.showSongBottomModal(context, item);
                                  } else {
                                    Modals.showPlaylistBottomModal(context, item);
                                  }
                                },
                                child: Container(
                                  height: 92,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border(
                                      left: BorderSide(
                                        color: highlight
                                            ? _primary
                                            : Colors.white.withValues(alpha: 0.15),
                                        width: highlight ? 4 : 2,
                                      ),
                                      top: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                      right: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 88,
                                        height: double.infinity,
                                        child: _cover(item),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _title(item).toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: highlight ? _primary : Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _subtitle(item).toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.labelSmall?.copyWith(
                                                  letterSpacing: 0.6,
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Icon(
                                          highlight
                                              ? Icons.equalizer
                                              : item['videoId'] != null
                                                  ? Icons.play_arrow
                                                  : Icons.arrow_forward,
                                          color: highlight
                                              ? _primary
                                              : Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          InkWell(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2)),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map> _flattenItems(List sections) {
    final out = <Map>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final contents = section['contents'];
      if (contents is List) {
        for (final c in contents) {
          if (c is Map) out.add(c);
        }
      }
    }
    return out;
  }

  Future<void> _openItem(BuildContext context, Map item) async {
    if (item['videoId'] != null) {
      await GetIt.I<MediaPlayer>().playSong(Map<String, dynamic>.from(item));
      return;
    }
    if (item['endpoint'] != null) {
      context.push('/browse', extra: {'endpoint': item['endpoint']});
    }
  }

  Widget _cover(Map item) {
    final thumbs = (item['thumbnails'] as List?) ?? const [];
    if (thumbs.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.08),
        child: const Icon(Icons.music_note),
      );
    }
    final url = (thumbs.first['url'] ?? '').toString();
    if (url.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.08),
        child: const Icon(Icons.music_note),
      );
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
      child: Image.network(url, fit: BoxFit.cover),
    );
  }

  String _title(Map item) => (item['title'] ?? 'Unknown').toString();

  String _subtitle(Map item) {
    final subtitle = item['subtitle']?.toString();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    if (item['artists'] is List) {
      final names = (item['artists'] as List)
          .map((e) => (e is Map ? e['name'] : null)?.toString())
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) return names;
    }
    return (item['type'] ?? 'RESULT').toString();
  }
}
