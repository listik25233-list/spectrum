import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'dart:math' as math;

class DjStationScreen extends ConsumerStatefulWidget {
  const DjStationScreen({super.key});

  @override
  ConsumerState<DjStationScreen> createState() => _DjStationScreenState();
}

class _DjStationScreenState extends ConsumerState<DjStationScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(djModeEnabledProvider);
    final isSpeaking = ref.watch(isHostSpeakingProvider);
    final hostMessages = ref.watch(djHostMessagesProvider);
    final queue = ref.watch(currentQueueProvider);
    final queueIndex = ref.watch(queueIndexProvider);

    return Scaffold(
      backgroundColor: SpectrumColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEURAL DJ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
                color: SpectrumColors.textPrimary,
              ),
            ),
            Text(
              'ORCHESTRATING SUBJECTIVE REALITY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 2.5,
                color: SpectrumColors.accent.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  children: [
                    // REACTIVE AI CORE
                    Center(
                        child: _AICore(
                            isActive: isEnabled, isSpeaking: isSpeaking)),
                    const SizedBox(height: 32),

                    // COMMAND CONSOLE
                    const _SectionHeader(label: 'COMMAND_INPUT', id: 'SH-01'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      maxLines: 2,
                      style: TextStyle(
                          color: SpectrumColors.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Опиши, что хочешь услышать...',
                        hintStyle: TextStyle(color: SpectrumColors.textMuted),
                        filled: true,
                        fillColor: SpectrumColors.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: SpectrumColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: SpectrumColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: SpectrumColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _loading
                                ? null
                                : () async {
                                    setState(() => _loading = true);
                                    await ref
                                        .read(audioPlayerServiceProvider)
                                        .startDjSession(
                                          prompt: _promptController.text.trim(),
                                          count: 5,
                                        );
                                    if (!mounted) return;
                                    setState(() => _loading = false);
                                  },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: SpectrumColors.accent.withOpacity(0.1),
                                border: Border.all(
                                    color:
                                        SpectrumColors.accent.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: _loading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: SpectrumColors.accent))
                                    : Text('EXECUTE NEURAL_LINK',
                                        style: TextStyle(
                                            color: SpectrumColors.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 1.0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: isEnabled
                              ? () => ref
                                  .read(audioPlayerServiceProvider)
                                  .stopDjSession()
                              : null,
                          child: Container(
                            height: 44,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(color: SpectrumColors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.power_settings_new_rounded,
                                color: isEnabled
                                    ? Colors.redAccent
                                    : SpectrumColors.textMuted,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // STATUS HUD
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HUDTag(
                            label: 'LINK',
                            value: isEnabled ? 'ESTABLISHED' : 'OFFLINE',
                            color: isEnabled
                                ? SpectrumColors.accent
                                : SpectrumColors.textMuted),
                        _HUDTag(
                            label: 'QUEUE', value: '${queue.length} TRACKS'),
                        _HUDTag(
                            label: 'BUFFER',
                            value:
                                '${(queue.length - 1 - math.max(0, queueIndex)).clamp(0, 99)} REMAINING'),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // NEURAL LOG
                    const _SectionHeader(
                        label: 'NEURAL_PHRASE_LOG', id: 'LOG-77'),
                    const SizedBox(height: 16),
                    if (hostMessages.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            border: Border.all(color: SpectrumColors.border),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '// WAITING FOR NEURAL LINK...\n// START DJ TO RECEIVE HOST PROTOCOLS',
                          style: TextStyle(
                              color: SpectrumColors.textMuted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              height: 1.5),
                        ),
                      )
                    else
                      ...hostMessages.reversed
                          .take(5)
                          .map((m) => _NeuralMessage(text: m)),

                    const SizedBox(height: 40),

                    // SIGNAL PATH (Queue)
                    const _SectionHeader(
                        label: 'SIGNAL_PATH_QUEUE', id: 'SQ-04'),
                    const SizedBox(height: 12),
                    ...queue.asMap().entries.take(15).map((entry) {
                      final isCurrent = entry.key == queueIndex;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? SpectrumColors.accent.withOpacity(0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: isCurrent
                                  ? SpectrumColors.accent.withOpacity(0.2)
                                  : Colors.transparent),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Text(
                            '[${(entry.key + 1).toString().padLeft(2, '0')}]',
                            style: TextStyle(
                                color: isCurrent
                                    ? SpectrumColors.accent
                                    : SpectrumColors.textUltraMuted,
                                fontSize: 10,
                                fontFamily: 'monospace'),
                          ),
                          title: Text(
                            entry.value.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? SpectrumColors.textPrimary
                                  : SpectrumColors.textSecondary,
                              fontWeight:
                                  isCurrent ? FontWeight.w900 : FontWeight.w500,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          subtitle: Text(
                            entry.value.artist,
                            style: TextStyle(
                                color: isCurrent
                                    ? SpectrumColors.accent.withOpacity(0.7)
                                    : SpectrumColors.textMuted,
                                fontSize: 10),
                          ),
                          trailing: isCurrent
                              ? Icon(Icons.graphic_eq_rounded,
                                  color: SpectrumColors.accent, size: 16)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AICore extends StatefulWidget {
  final bool isActive;
  final bool isSpeaking;
  const _AICore({required this.isActive, required this.isSpeaking});

  @override
  State<_AICore> createState() => _AICoreState();
}

class _AICoreState extends State<_AICore> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(_AICore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _pulseController.stop();
      _pulseController.animateTo(0.0,
          duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        var t = _rotationController.value;
        var p = _pulseController.value;

        if (!t.isFinite) t = 0.0;
        if (!p.isFinite) p = 0.0;

        final bass = p > 0
            ? (0.3 + 0.7 * math.sin(t * 2 * math.pi * 8.0).abs() * p)
                .clamp(0.0, 2.0)
            : 0.0;
        final mid = p > 0
            ? (0.2 + 0.8 * math.cos(t * 2 * math.pi * 15.0).abs() * p)
                .clamp(0.0, 2.0)
            : 0.0;
        // ignore: unused_local_variable
        final jitter = p > 0
            ? (math.sin(t * 2 * math.pi * 40.0) * 0.05 * p).clamp(-0.1, 0.1)
            : 0.0;

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. CIRCULAR SIGNAL ARRAY (The actual visualizer)
              if (widget.isActive)
                ...List.generate(24, (index) {
                  final angle = (index / 24) * 2 * math.pi;

                  // SIMULATED FREQUENCY SPECTRUM
                  // Low index = Bass, Mid index = Voice Formants, High index = Sibilance
                  final speed = 5.0 + (index * 0.8);
                  final phase = index * 0.5;

                  // Base procedural wave for this band
                  var barFreq = math.sin((t * speed) + phase).abs();

                  // Add high-frequency "jitter" to high-end bands
                  if (index > 16) {
                    barFreq += (math.sin(t * 50 + index) * 0.2).abs();
                  }

                  // AMPLITUDE MAPPING (The "Only what it hears" logic)
                  final bandAmplitude =
                      (math.sin(index * 1.5) * 0.5 + 0.5).clamp(0.0, 1.0);
                  final h = (6 + (barFreq * 50 * p * bandAmplitude))
                      .clamp(1.0, 200.0);

                  return Transform.rotate(
                    angle: angle + (t * 0.2), // Global slow rotation
                    child: Transform.translate(
                      offset: Offset(0, (-60 - (p * 8)).clamp(-100.0, 0.0)),
                      child: Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: SpectrumColors.accent.withOpacity(
                              (0.2 + (barFreq * 0.8 * p)).clamp(0.0, 1.0)),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            if (p > 0.4 && barFreq > 0.7)
                              BoxShadow(
                                  color: SpectrumColors.accent.withOpacity(0.3),
                                  blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              // 2. OUTER DATA RINGS
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SpectrumColors.accent.withOpacity(0.1 + (mid * 0.1)),
                    width: 0.5,
                  ),
                ),
              ),
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SpectrumColors.accent.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
              ),

              // 3. NEURAL CUBE (Reactive Core)
              Transform.scale(
                scale: (1.0 + (p * 0.1) + (bass * 0.2)).clamp(0.5, 3.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? SpectrumColors.accent
                        : SpectrumColors.textMuted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: SpectrumColors.accent.withOpacity(0.6),
                              blurRadius: (20 + (bass * 15)).clamp(0.01, 100.0),
                              spreadRadius: (1 + (mid * 3)).clamp(0.01, 100.0),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: widget.isActive
                        ? const Text('AI',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900))
                        : null,
                  ),
                ),
              ),

              // 4. ROTATING NEURAL SQUARE (Replaces scanning lines)
              if (widget.isActive)
                Transform.rotate(
                  angle: -t * 2 * math.pi,
                  child: Container(
                    width: 75 + (p * 15),
                    height: 75 + (p * 15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            SpectrumColors.accent.withOpacity(0.3 + (p * 0.4)),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              if (widget.isActive)
                Transform.rotate(
                  angle: t * math.pi,
                  child: Container(
                    width: 90 + (p * 10),
                    height: 90 + (p * 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            SpectrumColors.accent.withOpacity(0.1 + (p * 0.2)),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String id;
  const _SectionHeader({required this.label, required this.id});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 4, color: SpectrumColors.accent),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        const Spacer(),
        Text('[ $id ]',
            style: TextStyle(
                color: SpectrumColors.textUltraMuted,
                fontSize: 8,
                fontFamily: 'monospace')),
      ],
    );
  }
}

class _HUDTag extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _HUDTag({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SpectrumColors.surface,
        border: Border.all(color: SpectrumColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label:',
              style: TextStyle(
                  color: SpectrumColors.textUltraMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color ?? SpectrumColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _NeuralMessage extends StatelessWidget {
  final String text;
  const _NeuralMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpectrumColors.surface.withOpacity(0.5),
        border:
            Border(left: BorderSide(color: SpectrumColors.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REC_ NeuralProcessingStream',
              style: TextStyle(
                  color: SpectrumColors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontSize: 13,
                  height: 1.4)),
        ],
      ),
    );
  }
}
