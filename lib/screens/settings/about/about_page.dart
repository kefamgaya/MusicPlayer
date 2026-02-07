import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../generated/l10n.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _header(context),
              const SizedBox(height: 16),
              _brandCard(),
              const SizedBox(height: 14),
              _group(
                title: 'ABOUT',
                items: [
                  _item(
                    icon: Icons.person,
                    title: 'Developer',
                    subtitle: 'Sheikh Haziq',
                    onTap: () => _open('https://github.com/sheikhhaziq'),
                  ),
                  _item(
                    icon: Icons.link,
                    title: 'Website',
                    subtitle: 'gyawunmusic.vercel.app',
                    onTap: () => _open('https://gyawunmusic.vercel.app'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _group(
                title: 'COMMUNITY',
                items: [
                  _item(
                    icon: Icons.people,
                    title: 'Contributors',
                    subtitle: 'Open source contributors',
                    onTap: () => _open('https://github.com/jhelumcorp/gyawun/contributors'),
                  ),
                  _item(
                    icon: Icons.send,
                    title: 'Telegram',
                    subtitle: '@jhelumcorp',
                    onTap: () => _open('https://t.me/jhelumcorp'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _group(
                title: 'DEVELOPMENT',
                items: [
                  _item(
                    icon: Icons.code,
                    title: 'Source Code',
                    subtitle: 'GitHub repository',
                    onTap: () => _open('https://github.com/jhelumcorp/gyawun'),
                  ),
                  _item(
                    icon: Icons.bug_report,
                    title: 'Bug Report',
                    subtitle: 'Report issues',
                    onTap: () => _open(
                      'https://github.com/sheikhhaziq/gyawun_music/issues/new?template=bug_report.yml',
                    ),
                  ),
                  _item(
                    icon: Icons.description,
                    title: 'Feature Request',
                    subtitle: 'Discussions and requests',
                    onTap: () => _open('https://github.com/sheikhhaziq/gyawun_music/discussions'),
                  ),
                ],
              ),
            ],
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
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
              S.of(context).About.toUpperCase(),
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

  Widget _brandCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: _primary, width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(
              'assets/images/icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.music_note, size: 44),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'GYAWUN MUSIC',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _version == null ? 'VERSION --' : 'VERSION $_version',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: _primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _group({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _primary, width: 4)),
            ),
            child: Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 2.2,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              color: _primary.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.58)),
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
}
