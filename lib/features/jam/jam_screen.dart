import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/jam/jam_provider.dart';
import 'package:spectrum/features/jam/jam_models.dart';

class JamSessionScreen extends ConsumerStatefulWidget {
  const JamSessionScreen({super.key});

  @override
  ConsumerState<JamSessionScreen> createState() => _JamSessionScreenState();
}

class _JamSessionScreenState extends ConsumerState<JamSessionScreen> {
  bool _showScanner = false;

  @override
  Widget build(BuildContext context) {
    final jam = ref.watch(jamProvider);

    return Scaffold(
      backgroundColor: SpectrumColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'JAM SESSION',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.0,
            color: SpectrumColors.textPrimary,
          ),
        ),
        leading: _showScanner
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showScanner = false))
            : null,
        actions: [
          if (jam != null) ...[
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 18),
              onPressed: () => ref.read(jamProvider.notifier).forceRefresh(),
              tooltip: 'REFRESH QUEUE',
            ),
            TextButton(
              onPressed: () => ref.read(jamProvider.notifier).leaveSession(),
              child: Text('DISCONNECT',
                  style: TextStyle(
                      color: SpectrumColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: _showScanner
          ? _buildScanner(context)
          : (jam == null
              ? _buildHome(context)
              : _buildActiveRoom(context, jam)),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            final code = barcode.rawValue!;
            if (code.length == 5) {
              ref.read(jamProvider.notifier).joinSession(code);
              setState(() => _showScanner = false);
            }
          }
        }
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    final codeController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.hub_rounded,
              size: 80, color: SpectrumColors.accent.withOpacity(0.2)),
          const SizedBox(height: 32),
          Text(
            'LISTEN TOGETHER',
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Collaborate on queues and sync streams with QR sharing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SpectrumColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => ref.read(jamProvider.notifier).createSession(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('START NEW JAM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SpectrumColors.accent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showScanner = true),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('SCAN QR CODE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SpectrumColors.textPrimary,
              side: BorderSide(color: SpectrumColors.borderStrong),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white10)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR JOIN ACTIVE',
                    style: TextStyle(
                        color: SpectrumColors.textUltraMuted, fontSize: 10)),
              ),
              const Expanded(child: Divider(color: Colors.white10)),
            ],
          ),
          const SizedBox(height: 16),
          _ActiveSessionsList(),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white10)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR USE CODE',
                    style: TextStyle(
                        color: SpectrumColors.textUltraMuted, fontSize: 10)),
              ),
              const Expanded(child: Divider(color: Colors.white10)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: codeController,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 8),
            decoration: InputDecoration(
              hintText: 'CODE',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.05)),
              filled: true,
              fillColor: SpectrumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
            onSubmitted: (val) {
              if (val.length == 5)
                ref.read(jamProvider.notifier).joinSession(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoom(BuildContext context, JamSession jam) {
    final myId = ref.read(jamProvider.notifier).myMemberId;
    final isHost = jam.hostId == myId;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Room QR Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: SpectrumColors.accent.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: -10),
                    ],
                  ),
                  child: QrImageView(
                    data: jam.id,
                    version: QrVersions.auto,
                    size: 180.0,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                jam.id,
                style: TextStyle(
                    color: SpectrumColors.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8),
              ),
              Text('SCAN TO JOIN THE JAM',
                  style: TextStyle(
                      color: SpectrumColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 40),
              _SectionHeader(title: 'MEMBERS', count: jam.members.length),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: jam.members.length,
                  itemBuilder: (ctx, idx) {
                    final m = jam.members[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: m.isHost
                                ? SpectrumColors.accent
                                : SpectrumColors.surface,
                            child: Icon(
                                m.isHost
                                    ? Icons.bolt_rounded
                                    : Icons.person_rounded,
                                color:
                                    m.isHost ? Colors.black : Colors.white24),
                          ),
                          const SizedBox(height: 4),
                          Text(m.name.split(' ').first,
                              style: TextStyle(
                                  color: SpectrumColors.textPrimary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
              _SectionHeader(
                  title: 'SHARED QUEUE', count: jam.sharedQueue.length),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = jam.sharedQueue[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: SpectrumColors.surface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(track.albumArtUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.white10)),
                    ),
                    title: Text(track.title,
                        style: TextStyle(
                            color: SpectrumColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(track.artist,
                        style: TextStyle(
                            color: SpectrumColors.textMuted, fontSize: 11)),
                    trailing: Icon(Icons.drag_handle_rounded,
                        color: SpectrumColors.textUltraMuted, size: 18),
                  ),
                );
              },
              childCount: jam.sharedQueue.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionsAsync = ref.watch(activeJamSessionsProvider);

    return activeSessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('NO ACTIVE JAMS NEARBY',
                  style: TextStyle(
                      color: SpectrumColors.textUltraMuted, fontSize: 11)),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: SpectrumColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                onTap: () =>
                    ref.read(jamProvider.notifier).joinSession(session['id']),
                leading: CircleAvatar(
                  backgroundColor: SpectrumColors.accent.withOpacity(0.1),
                  child: Icon(Icons.hub_rounded,
                      color: SpectrumColors.accent, size: 20),
                ),
                title: Text(
                  '${session['hostName']}\'s JAM',
                  style: TextStyle(
                      color: SpectrumColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                subtitle: Text(
                  '${session['memberCount']} MEMBERS • CODE: ${session['id']}',
                  style:
                      TextStyle(color: SpectrumColors.textMuted, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (e, stack) => Center(
          child: Text('ERROR LOADING JAMS',
              style: TextStyle(color: SpectrumColors.accent, fontSize: 10))),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(width: 4, height: 4, color: SpectrumColors.accent),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const Spacer(),
          Text('$count',
              style: TextStyle(
                  color: SpectrumColors.accent,
                  fontSize: 10,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
