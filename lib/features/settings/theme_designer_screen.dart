import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:spectrum/features/settings/settings_providers.dart';

class ThemeDesignerScreen extends ConsumerWidget {
  const ThemeDesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(spectrumThemeProvider);
    final notifier = ref.read(spectrumThemeProvider.notifier);

    return Scaffold(
      backgroundColor: SpectrumColors.background,
      appBar: AppBar(
        title: const Text('Design System Designer',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: SpectrumColors.surface,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => notifier.reset(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('RESET',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLivePreview(theme),
            const SizedBox(height: 32),
            _buildSectionHeader('Core Surfaces'),
            _buildColorTile(context, 'Background', Color(theme.backgroundColor),
                (c) => notifier.updateColor('bg', c)),
            _buildColorTile(
                context,
                'Surface (Panels)',
                Color(theme.surfaceColor),
                (c) => notifier.updateColor('surf', c)),
            _buildColorTile(context, 'Card Elevation', Color(theme.cardColor),
                (c) => notifier.updateColor('crd', c)),
            const SizedBox(height: 24),
            _buildSectionHeader('Accents & HUD'),
            _buildColorTile(context, 'Primary Accent', Color(theme.accentColor),
                (c) => notifier.updateColor('accent', c)),
            _buildColorTile(context, 'HUD Border', Color(theme.borderColor),
                (c) => notifier.updateColor('border', c)),
            const SizedBox(height: 24),
            _buildSectionHeader('Typography'),
            _buildColorTile(
                context,
                'Text Primary',
                Color(theme.textPrimaryColor),
                (c) => notifier.updateColor('textP', c)),
            _buildColorTile(
                context,
                'Text Secondary',
                Color(theme.textSecondaryColor),
                (c) => notifier.updateColor('textS', c)),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: SpectrumColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0),
      ),
    );
  }

  Widget _buildColorTile(BuildContext context, String label, Color color,
      ValueChanged<Color> onSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: SpectrumColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SpectrumColors.divider),
      ),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
          style: TextStyle(
              color: SpectrumColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace'),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
            ],
          ),
        ),
        onTap: () => _pickColor(context, label, color, onSelected),
      ),
    );
  }

  void _pickColor(BuildContext context, String label, Color initialColor,
      ValueChanged<Color> onSelected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpectrumColors.surface,
        title: Text('Pick $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onSelected,
            enableAlpha: true,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(theme.backgroundColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(theme.borderColor), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Color(theme.accentColor).withOpacity(0.1), blurRadius: 40),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(theme.accentColor),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HUD PREVIEW',
                style: TextStyle(
                  color: Color(theme.textPrimaryColor),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(theme.surfaceColor),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Color(theme.borderColor).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(theme.cardColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.music_note,
                      color: Color(theme.accentColor), size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spectrum Audio',
                        style: TextStyle(
                            color: Color(theme.textPrimaryColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text('Visual System Active',
                        style: TextStyle(
                            color: Color(theme.textSecondaryColor),
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
