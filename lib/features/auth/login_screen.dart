import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/auth/spotify_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _connectSpotify() async {
    setState(() => _loading = true);
    try {
      await SpotifyAuthService().authenticate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка входа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ),
                    ),
                    child: const Icon(Icons.equalizer_rounded,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Spectrum',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Все сервисы. Один плеер.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Spotify login button
                  _ServiceButton(
                    label: 'Войти через Spotify',
                    icon: Icons.music_note,
                    color: const Color(0xFF1DB954),
                    onTap: _loading ? null : _connectSpotify,
                    loading: _loading,
                  ),
                  const SizedBox(height: 16),

                  // Placeholder buttons for future services
                  _ServiceButton(
                    label: 'Apple Music',
                    icon: Icons.apple,
                    color: const Color(0xFFFC3C44),
                    onTap: null,
                    comingSoon: true,
                  ),
                  const SizedBox(height: 16),
                  _ServiceButton(
                    label: 'YouTube Music',
                    icon: Icons.play_circle_outline,
                    color: const Color(0xFFFF0000),
                    onTap: null,
                    comingSoon: true,
                  ),
                  const SizedBox(height: 16),
                  _ServiceButton(
                    label: 'Deezer / Tidal',
                    icon: Icons.headphones,
                    color: const Color(0xFF9B59B6),
                    onTap: null,
                    comingSoon: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool comingSoon;

  const _ServiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                color: color.withOpacity(0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (loading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else if (comingSoon)
                      Text(
                        'Скоро',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.4), size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
