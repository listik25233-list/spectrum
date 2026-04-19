import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/lyrics_provider.dart';

class SyncedLyricsView extends ConsumerStatefulWidget {
  final bool compact;
  const SyncedLyricsView({super.key, this.compact = false});

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  DateTime? _lastScrollTime;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive(int index) {
    if (_isUserScrolling || !_scrollController.hasClients) return;

    // Wait a bit if user just scrolled manually
    if (_lastScrollTime != null &&
        DateTime.now().difference(_lastScrollTime!) < const Duration(seconds: 2)) {
      return;
    }

    // Logic to center the active line
    final double itemHeight = widget.compact ? 50 : 70;
    final double targetOffset = (index * itemHeight) - (200); // 200 is approx half-height

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(lyricsProvider);
    final activeIndex = ref.watch(currentLyricIndexProvider);

    if (lines.isEmpty) {
      final manualContent = ref.watch(manualLyricsContentProvider);
      final track = ref.watch(currentTrackProvider);
      final displayContent = manualContent ?? track?.lyrics;

      if (displayContent != null && displayContent.trim().isNotEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          physics: const BouncingScrollPhysics(),
          child: Text(
            displayContent.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
        );
      }

      return const Center(
        child: Text(
          'ТЕКСТ ПЕСНИ НЕ НАЙДЕН',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Trigger auto-scroll
    ref.listen(currentLyricIndexProvider, (prev, next) {
      if (next >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToActive(next);
        });
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          if (notification.dragDetails != null) _isUserScrolling = true;
        } else if (notification is ScrollEndNotification) {
          _isUserScrolling = false;
          _lastScrollTime = DateTime.now();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 24),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final isActive = index == activeIndex;
          final line = lines[index];

          return GestureDetector(
            onTap: () {
              ref.read(audioPlayerServiceProvider).seek(line.startTime);
              HapticFeedback.lightImpact();
            },
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: isActive ? 28 : 22,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.2),
                letterSpacing: -0.5,
                height: 1.5,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(line.text.toUpperCase()),
              ),
            ),
          );
        },
      ),
    );
  }
}
