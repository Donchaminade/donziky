import 'dart:math' as math;

import 'package:donziker/providers/music_provider.dart';
import 'package:donziker/providers/theme_provider.dart';
import 'package:donziker/screens/home_screen.dart';
import 'package:donziker/screens/splash_permission_screen.dart';
import 'package:donziker/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Durée totale du splash à l'ouverture (modifier ici : 5000 ou 7000 ms).
const kSplashDuration = Duration(seconds: 5);

/// Splash d'ouverture premium — animations, puis accueil ou permissions.
class WowSplashScreen extends StatefulWidget {
  const WowSplashScreen({super.key});

  @override
  State<WowSplashScreen> createState() => _WowSplashScreenState();
}

class _WowSplashScreenState extends State<WowSplashScreen> with TickerProviderStateMixin {
  static const _surface = Color(0xFF0A0A0A);

  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _orbit;
  late final AnimationController _eq;
  late final AnimationController _shimmer;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _glowExpand;

  bool _navigated = false;
  bool _goHome = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _intro = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (kSplashDuration.inMilliseconds * 0.55).round()),
    );
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _eq = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _textSlide = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _glowExpand = Tween<double>(begin: 0.6, end: 1.35).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic)),
    );

    _intro.forward();
    _launch();
  }

  Future<void> _launch() async {
    final permissionService = PermissionService();
    final music = context.read<MusicProvider>();

    final bootstrap = Future.wait([
      Future.delayed(kSplashDuration),
      () async {
        await music.refreshPermissionStatus();
        if (music.permissionGranted) {
          await permissionService.ensureNotificationPermission();
        }
      }(),
    ]);

    await bootstrap;

    if (!mounted || _navigated) return;
    _goHome = music.permissionGranted;
    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final next = _goHome
        ? const HomeScreen()
        : const SplashPermissionScreen(skipIntro: true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _orbit.dispose();
    _eq.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<ThemeProvider>().accentColor;

    return Scaffold(
      backgroundColor: _surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse, _orbit, _eq, _shimmer]),
        builder: (context, _) {
          final pulse = 0.85 + _pulse.value * 0.15;
          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedGradientBackground(progress: _intro.value, accent: accent),
              CustomPaint(
                painter: _ParticleFieldPainter(
                  progress: _orbit.value,
                  accent: accent,
                  particleCount: 48,
                ),
              ),
              CustomPaint(
                painter: _WavePainter(
                  progress: _eq.value,
                  accent: accent.withValues(alpha: 0.35),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoFade.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _glowExpand.value * pulse,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.55),
                                      accent.withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: _orbit.value * math.pi * 2,
                              child: Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.music_note_rounded,
                                    size: 64,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -6,
                              child: _EqualizerBars(
                                progress: _eq.value,
                                accent: accent,
                                barCount: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textFade.value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                final slide = (_shimmer.value * 2 - 1) * bounds.width;
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white,
                                    accent,
                                    Colors.white,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  transform: GradientTranslation(slide, 0),
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'DonZiker',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Votre musique. Sans limites.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Opacity(
                      opacity: _textFade.value * 0.9,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  final double progress;
  final Color accent;

  const _AnimatedGradientBackground({required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0 + progress * 0.4, -1),
          end: Alignment(1.0 - progress * 0.3, 1.2),
          colors: [
            const Color(0xFF0A0A0A),
            accent.withValues(alpha: 0.22),
            const Color(0xFF14101A),
            const Color(0xFF0A0A0A),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  final double progress;
  final Color accent;
  final int barCount;

  const _EqualizerBars({
    required this.progress,
    required this.accent,
    required this.barCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (i) {
        final phase = (progress + i / barCount) % 1.0;
        final h = 8.0 + math.sin(phase * math.pi * 2) * 10 + math.sin(phase * math.pi * 4) * 4;
        return Container(
          width: 4,
          height: h.clamp(4.0, 22.0),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [accent.withValues(alpha: 0.5), accent],
            ),
          ),
        );
      }),
    );
  }
}

class _ParticleFieldPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final int particleCount;

  _ParticleFieldPainter({
    required this.progress,
    required this.accent,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < particleCount; i++) {
      final bx = rnd.nextDouble();
      final by = rnd.nextDouble();
      final orbit = (progress + i / particleCount) % 1.0;
      final x = (bx * size.width + math.sin(orbit * math.pi * 2 + i) * 24) % size.width;
      final y = (by * size.height + math.cos(orbit * math.pi * 2 + i * 0.7) * 18) % size.height;
      final radius = 1.2 + rnd.nextDouble() * 2.2;
      final alpha = 0.15 + rnd.nextDouble() * 0.35;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = (i.isEven ? accent : Colors.white).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticleFieldPainter old) => old.progress != progress;
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color accent;

  _WavePainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var w = 0; w < 3; w++) {
      final path = Path();
      final baseY = size.height * (0.72 + w * 0.06);
      path.moveTo(0, baseY);
      for (var x = 0.0; x <= size.width; x += 6) {
        final n = x / size.width;
        final y = baseY +
            math.sin((n * 4 + progress * 2 + w) * math.pi * 2) * (12 - w * 3) +
            math.sin((n * 8 + progress) * math.pi) * 4;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint..color = accent.withValues(alpha: 0.12 - w * 0.03));
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

/// Décale un gradient pour l'effet shimmer du titre.
class GradientTranslation extends GradientTransform {
  final double dx;
  final double dy;

  const GradientTranslation(this.dx, this.dy);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, dy, 0);
  }
}
