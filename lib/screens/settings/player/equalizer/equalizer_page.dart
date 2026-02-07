import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/equalizer_state.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_cubit.dart';
import 'package:gyawun/screens/settings/player/equalizer/cubit/loudness_state.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:gyawun/utils/adaptive_widgets/slider.dart';
import 'package:just_audio/just_audio.dart';

class EqualizerPage extends StatelessWidget {
  const EqualizerPage({super.key});

  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _primary = Color(0xFF10B981);

  Future<Widget> _build(BuildContext context) async {
    final settings = GetIt.I<SettingsManager>();
    final androidEq = GetIt.I<AndroidEqualizer>();
    final params = await androidEq.parameters;

    final eqCubit = EqualizerCubit(
      enabled: settings.equalizerEnabled,
      minDb: params.minDecibels,
      maxDb: params.maxDecibels,
      bands: params.bands
          .map(
            (b) => EqBand(
              index: b.index,
              centerFrequency: b.centerFrequency,
              gain: b.gain,
            ),
          )
          .toList(),
    );

    final loudnessCubit = LoudnessCubit(
      enabled: settings.loudnessEnabled,
      targetGain: settings.loudnessTargetGain,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: eqCubit),
        BlocProvider.value(value: loudnessCubit),
      ],
      child: const _EqualizerView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _bg,
        textTheme: textTheme,
      ),
      child: FutureBuilder(
        future: _build(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: _bg,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}

class _EqualizerView extends StatelessWidget {
  const _EqualizerView();

  @override
  Widget build(BuildContext context) {
    final mediaPlayer = GetIt.I<MediaPlayer>();
    final settings = GetIt.I<SettingsManager>();

    return Scaffold(
      backgroundColor: EqualizerPage._bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _header(context),
            const SizedBox(height: 14),
            _section(
              title: 'LOUDNESS',
              child: BlocBuilder<LoudnessCubit, LoudnessState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _switchRow(
                        icon: Icons.volume_up,
                        title: S.of(context).Loudness_Enhancer,
                        subtitle: 'Boost perceived volume with target gain',
                        value: state.enabled,
                        onChanged: (val) async {
                          context.read<LoudnessCubit>().toggle(val);
                          await mediaPlayer.setLoudnessEnabled(val);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TARGET GAIN',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              min: -1,
                              max: 1,
                              value: state.targetGain,
                              activeColor: EqualizerPage._primary,
                              onChanged: state.enabled
                                  ? (val) async {
                                      context.read<LoudnessCubit>().setTargetGain(val);
                                      await mediaPlayer.setLoudnessTargetGain(val);
                                    }
                                  : null,
                            ),
                            Text(
                              state.targetGain.toStringAsFixed(2),
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: EqualizerPage._primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'EQUALIZER',
              child: BlocBuilder<EqualizerCubit, EqualizerState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _switchRow(
                        icon: Icons.equalizer,
                        title: S.of(context).Enable_Equalizer,
                        subtitle: 'Manual multi-band frequency control',
                        value: state.enabled,
                        onChanged: (val) async {
                          context.read<EqualizerCubit>().toggle(val);
                          await mediaPlayer.setEqualizerEnabled(val);
                        },
                      ),
                      if (state.enabled)
                        Container(
                          height: 300,
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final band in state.bands)
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        band.gain.toStringAsFixed(1),
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 10,
                                          color: EqualizerPage._primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: AdaptiveSlider(
                                          vertical: true,
                                          min: state.minDb,
                                          max: state.maxDb,
                                          value: band.gain,
                                          onChanged: (val) async {
                                            context.read<EqualizerCubit>().setBandGain(band.index, val);
                                            await settings.setEqualizerBandsGain(band.index, val);
                                            final params = await GetIt.I<AndroidEqualizer>().parameters;
                                            await params.bands[band.index].setGain(val);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${band.centerFrequency.round()}Hz',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 9,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
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
              S.of(context).Loudness_And_Equalizer.toUpperCase(),
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

  Widget _section({required String title, required Widget child}) {
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
              border: Border(left: BorderSide(color: EqualizerPage._primary, width: 4)),
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
          child,
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            color: EqualizerPage._primary.withValues(alpha: 0.2),
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
          Switch(value: value, activeColor: EqualizerPage._primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
