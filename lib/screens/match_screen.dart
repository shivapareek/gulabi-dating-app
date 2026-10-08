import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class MatchScreen extends StatefulWidget {
  final UserProfile other;
  final String matchId;
  const MatchScreen({super.key, required this.other, required this.matchId});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward();
  final _rand = Random();
  late final List<List<double>> _hearts = List.generate(
      18, (_) => [_rand.nextDouble(), _rand.nextDouble() * 0.6, 14 + _rand.nextDouble() * 22]);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = app.me!;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: Colors.black.withOpacity(0.72),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = Curves.easeOutBack.transform(min(1, _c.value * 1.4));
              return Stack(children: [
                // Floating hearts.
                for (final h in _hearts)
                  Positioned(
                    left: h[0] * size.width,
                    top: size.height * (1 - _c.value * (0.6 + h[1])),
                    child: Opacity(
                      opacity: (1 - _c.value).clamp(0, 1).toDouble(),
                      child: Icon(Icons.favorite, color: Brand.pink, size: h[2]),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(children: [
                      const Spacer(),
                      Transform.scale(
                        scale: t,
                        child: ShaderMask(
                          shaderCallback: (r) => Brand.gradient.createShader(r),
                          child: const Text("It's a Match!",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _c.value.clamp(0, 1).toDouble(),
                        child: Text('You and ${widget.other.name} liked each other',
                            style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 170,
                        child: Stack(alignment: Alignment.center, children: [
                          Transform.translate(
                            offset: Offset(-60 - (1 - t) * 200, 0),
                            child: Transform.rotate(
                                angle: -0.15, child: _ring(me.photos.firstOrNull, me.name)),
                          ),
                          Transform.translate(
                            offset: Offset(60 + (1 - t) * 200, 0),
                            child: Transform.rotate(
                                angle: 0.15,
                                child: _ring(widget.other.photos.firstOrNull, widget.other.name)),
                          ),
                          Transform.scale(
                            scale: t,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.favorite, color: Brand.pink, size: 30),
                            ),
                          ),
                        ]),
                      ),
                      const Spacer(),
                      GradientButton('Send a message',
                          icon: Icons.chat_bubble_rounded, onTap: () {
                        Navigator.of(context).pushReplacement(fadeRoute(ChatScreen(
                            matchId: widget.matchId, other: widget.other)));
                      }),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Keep swiping',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ]),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _ring(String? url, String name) => Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(gradient: Brand.gradient, shape: BoxShape.circle),
        child: Avatar(url, name: name, size: 140),
      );
}
