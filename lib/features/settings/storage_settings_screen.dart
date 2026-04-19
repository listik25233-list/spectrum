import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/settings/storage_service.dart';
import 'package:spectrum/features/settings/settings_providers.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';

class StorageSettingsScreen extends ConsumerWidget {
  const StorageSettingsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    var mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    var gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageInfoProvider);

    return Scaffold(
      backgroundColor: SpectrumColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            collapsedHeight: 70,
            pinned: true,
            backgroundColor: SpectrumColors.background.withOpacity(0.85),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                'STORAGE_VAULT',
                style: TextStyle(
                  color: SpectrumColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: storageAsync.when(
              data: (info) => _buildContent(context, ref, info),
              loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, __) => Center(
                  child: Text('ENGINE_SYSERR: $e',
                      style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, StorageInfo info) {
    final permanentRatio =
        info.totalUsed > 0 ? info.permanentSize / info.totalUsed : 0.0;
    final cacheRatio =
        info.totalUsed > 0 ? info.cacheSize / info.totalUsed : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MASTER METRIC CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SpectrumColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SpectrumColors.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL_DISK_OCCUPATION',
                    style: TextStyle(
                        color: SpectrumColors.textUltraMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  _formatBytes(info.totalUsed),
                  style: TextStyle(
                      color: SpectrumColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0),
                ),
                const SizedBox(height: 32),

                // MULTI-SECTOR STATUS BAR
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2)),
                  child: Row(
                    children: [
                      if (permanentRatio > 0)
                        Flexible(
                          flex: (permanentRatio * 1000).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: SpectrumColors.accent,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        SpectrumColors.accent.withOpacity(0.4),
                                    blurRadius: 10)
                              ],
                            ),
                          ),
                        ),
                      if (cacheRatio > 0)
                        Flexible(
                          flex: (cacheRatio * 1000).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: SpectrumColors.accentSecondary,
                              boxShadow: [
                                BoxShadow(
                                    color: SpectrumColors.accentSecondary
                                        .withOpacity(0.4),
                                    blurRadius: 10)
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // DATA SECTORS
                _DataSector(
                  label: 'PERMANENT_SIGNALS',
                  size: _formatBytes(info.permanentSize),
                  meta: '${info.downloadedCount} OBJECTS',
                  color: SpectrumColors.accent,
                ),
                const SizedBox(height: 20),
                _DataSector(
                  label: 'VOLATILE_CACHE',
                  size: _formatBytes(info.cacheSize),
                  meta: 'STREAMING_TEMPORALS',
                  color: SpectrumColors.accentSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          _buildSubHeader('CACHE_PROTOCOL', 'STORAGE-SEC'),
          const SizedBox(height: 16),
          _buildCacheControls(context, ref),

          const SizedBox(height: 48),
          _buildSubHeader('STORAGE_MAINTENANCE', 'MNT-RX'),
          const SizedBox(height: 16),

          // ACTIONS
          _ActionCard(
            title: 'PURGE_TEMPORALS',
            subtitle: 'Delete streaming cache. Local library remains locked.',
            color: SpectrumColors.accentSecondary,
            icon: Icons.auto_delete_outlined,
            onPressed: () async {
              await ref.read(storageServiceProvider).clearCache();
              ref.invalidate(storageInfoProvider);
            },
          ),
          const SizedBox(height: 16),
          _ActionCard(
            title: 'WIPE_OBJECT_VAULT',
            subtitle: 'Irreversibly delete all offline signal data.',
            color: Colors.redAccent,
            icon: Icons.delete_forever_outlined,
            onPressed: () async {
              final confirm = await _showConfirmDialog(context);
              if (confirm) {
                await ref.read(storageServiceProvider).deleteAllDownloads();
                ref.invalidate(storageInfoProvider);
              }
            },
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title, String id) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                color: SpectrumColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0)),
        const Spacer(),
        Text('[ $id ]',
            style: TextStyle(
                color: SpectrumColors.textUltraMuted,
                fontSize: 8,
                fontFamily: 'monospace')),
      ],
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: SpectrumColors.surface,
            title: Text('WIPE_SECURITY_CHECK',
                style: TextStyle(
                    color: SpectrumColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
            content: Text('THIS ACTION WILL PURGE ALL LOCAL SIGNALS. PROCEED?',
                style:
                    TextStyle(color: SpectrumColors.textMuted, fontSize: 12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ABORT')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('ENGAGE_WIPE',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildCacheControls(BuildContext context, WidgetRef ref) {
    final cacheSettings = ref.watch(cacheSettingsProvider);
    final limit = cacheSettings.maxCacheSizeGb;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpectrumColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SpectrumColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIMIT_THRESHOLD',
                  style: TextStyle(
                      color: SpectrumColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0)),
              Text('${limit.toInt()} GB',
                  style: TextStyle(
                      color: SpectrumColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SpectrumColors.accent,
              inactiveTrackColor: Colors.black26,
              thumbColor: SpectrumColors.accent,
              overlayColor: SpectrumColors.accent.withOpacity(0.2),
              trackHeight: 2,
            ),
            child: Slider(
              value: limit,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (val) {
                ref.read(cacheSettingsProvider.notifier).updateLimit(val);
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTIFY_ON_CRITICAL',
                      style: TextStyle(
                          color: SpectrumColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0)),
                  const Text('Alert when cache > limit',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Switch(
                value: cacheSettings.notificationsEnabled,
                activeColor: SpectrumColors.accent,
                onChanged: (val) {
                  ref.read(cacheSettingsProvider.notifier).toggleNotifications(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataSector extends StatelessWidget {
  final String label;
  final String size;
  final String meta;
  final Color color;

  const _DataSector(
      {required this.label,
      required this.size,
      required this.meta,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(1))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: SpectrumColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0)),
              Text(meta,
                  style: TextStyle(
                      color: SpectrumColors.textUltraMuted,
                      fontSize: 9,
                      fontFamily: 'monospace')),
            ],
          ),
        ),
        Text(size,
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace')),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionCard(
      {required this.title,
      required this.subtitle,
      required this.color,
      required this.icon,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SpectrumColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SpectrumColors.border.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: TextStyle(
                color: SpectrumColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.0)),
        subtitle: Text(subtitle,
            style: TextStyle(color: SpectrumColors.textMuted, fontSize: 10)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: SpectrumColors.textUltraMuted, size: 16),
      ),
    );
  }
}
