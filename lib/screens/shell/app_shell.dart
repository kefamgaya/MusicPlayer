import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/update_service/update_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../generated/l10n.dart';
import 'widgets/bottom_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (value.isNotEmpty) _handleIntent(value.first);
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) _handleIntent(value.first);
        ReceiveSharingIntent.instance.reset();
      });
    }

    UpdateService.autoCheck(context);
  }

  void _handleIntent(SharedMediaFile value) {
    if (value.mimeType == 'text/plain' && value.path.contains('music.youtube.com')) {
      final uri = Uri.tryParse(value.path);
      if (uri == null) return;

      if (uri.pathSegments.first == 'watch' && uri.queryParameters['v'] != null) {
        context.push('/player', extra: uri.queryParameters['v']);
      } else if (uri.pathSegments.first == 'playlist' && uri.queryParameters['list'] != null) {
        final id = uri.queryParameters['list']!;
        context.push(
          '/browse',
          extra: {
            'endpoint': {'browseId': id.startsWith('VL') ? id : 'VL$id'},
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final path = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (width >= 450)
                  _SideRail(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onTap: _goBranch,
                    homeLabel: S.of(context).Home,
                    settingsLabel: S.of(context).Settings,
                  ),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
          const BottomPlayer(),
        ],
      ),
      bottomNavigationBar: width < 450
          ? _BottomNav(
              selectedIndex: widget.navigationShell.currentIndex,
              currentPath: path,
              onTap: _goBranch,
              homeLabel: S.of(context).Home,
              settingsLabel: S.of(context).Settings,
            )
          : null,
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.selectedIndex,
    required this.onTap,
    required this.homeLabel,
    required this.settingsLabel,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String homeLabel;
  final String settingsLabel;

  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 2),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _RailBtn(
            icon: Icons.home,
            label: homeLabel,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(height: 10),
          _RailBtn(
            icon: Icons.library_music,
            label: 'Library',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(height: 10),
          _RailBtn(
            icon: Icons.settings,
            label: settingsLabel,
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          const Spacer(),
          Container(height: 4, width: 40, color: _primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RailBtn extends StatelessWidget {
  const _RailBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.transparent,
          border: Border.all(
            color: selected ? _primary : Colors.white.withValues(alpha: 0.14),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.white),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.currentPath,
    required this.onTap,
    required this.homeLabel,
    required this.settingsLabel,
  });

  final int selectedIndex;
  final String currentPath;
  final ValueChanged<int> onTap;
  final String homeLabel;
  final String settingsLabel;

  @override
  Widget build(BuildContext context) {
    final homeSelected = selectedIndex == 0 && !currentPath.startsWith('/search');
    final exploreSelected = currentPath.startsWith('/search') || currentPath.startsWith('/browse') || currentPath.startsWith('/chip');
    final librarySelected = selectedIndex == 1 && !currentPath.startsWith('/library/history');
    final podcastsSelected = currentPath.startsWith('/library/history');
    final settingsSelected = selectedIndex == 2;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomBtn(
            icon: Icons.home,
            selected: homeSelected,
            onTap: () => onTap(0),
            label: homeLabel,
          ),
          _BottomBtn(
            icon: Icons.explore,
            selected: exploreSelected,
            onTap: () => context.go('/search'),
            label: 'Explore',
          ),
          _BottomBtn(
            icon: Icons.library_music,
            selected: librarySelected,
            onTap: () => onTap(1),
            label: 'Library',
          ),
          _BottomBtn(
            icon: Icons.podcasts,
            selected: podcastsSelected,
            onTap: () => context.go('/library/history'),
            label: 'Podcasts',
          ),
          _BottomBtn(
            icon: Icons.settings,
            selected: settingsSelected,
            onTap: () => onTap(2),
            label: settingsLabel,
          ),
        ],
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  static const Color _primary = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 54,
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.transparent,
          border: Border.all(
            color: selected ? _primary : Colors.white.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
