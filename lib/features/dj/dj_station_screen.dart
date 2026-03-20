import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/player/audio_player_service.dart';
import 'package:spectrum/features/player/mini_player.dart';

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
    final hostMessages = ref.watch(djHostMessagesProvider);
    final queue = ref.watch(currentQueueProvider);
    final queueIndex = ref.watch(queueIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('DJ Station', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  children: [
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Опиши, что хочешь услышать. Например: "Только The Weeknd, ночной вайб, 5 треков"',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _loading
                              ? null
                              : () async {
                                  setState(() => _loading = true);
                                  final result = await ref.read(audioPlayerServiceProvider).startDjSession(
                                        prompt: _promptController.text.trim(),
                                        count: 5,
                                      );
                                  setState(() => _loading = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result.phrase)),
                                    );
                                  }
                                },
                          icon: _loading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.play_arrow_rounded),
                          label: const Text('Запустить DJ'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: isEnabled
                              ? () {
                                  ref.read(audioPlayerServiceProvider).stopDjSession();
                                }
                              : null,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Остановить DJ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _chip(isEnabled ? 'DJ активен' : 'DJ выключен', isEnabled ? Colors.green : Colors.white38),
                        _chip('Текущая очередь: ${queue.length}', Colors.white54),
                        _chip('Осталось: ${queue.isEmpty || queueIndex < 0 ? 0 : queue.length - 1 - queueIndex}', Colors.white54),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Фразы DJ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (hostMessages.isEmpty)
                      const Text('Пока нет фраз. Запусти DJ, чтобы начать подборки.', style: TextStyle(color: Colors.white54))
                    else
                      ...hostMessages
                          .skip(hostMessages.length > 8 ? hostMessages.length - 8 : 0)
                          .map(
                        (m) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(m),
                        ),
                      ),
                    const SizedBox(height: 14),
                    const Text('Текущая очередь', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...queue.asMap().entries.take(20).map(
                          (entry) => ListTile(
                            dense: true,
                            leading: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white54)),
                            title: Text(
                              entry.value.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: entry.key == queueIndex ? Colors.white : Colors.white70,
                                fontWeight: entry.key == queueIndex ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(entry.value.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
