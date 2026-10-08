import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/jaipur_areas.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// One profile card: tap left/right to flip photos, shows LIKE/NOPE stamps
/// based on how far it is dragged ([drag] is -1..1 horizontally, -1..0 up).
class SwipeCard extends StatefulWidget {
  final UserProfile p;
  final Offset drag;
  final VoidCallback onInfo;
  const SwipeCard(
      {super.key, required this.p, this.drag = Offset.zero, required this.onInfo});
  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final photos = p.photos.isEmpty ? <String?>[null] : p.photos;
    final km = app.me == null ? 0 : distanceKm(app.me!.area, p.area);
    final likeO = widget.drag.dx.clamp(0.0, 1.0);
    final nopeO = (-widget.drag.dx).clamp(0.0, 1.0);
    final superO = (-widget.drag.dy).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(fit: StackFit.expand, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: SizedBox.expand(
            key: ValueKey(_photo),
            child: Photo(photos[_photo.clamp(0, photos.length - 1)], name: p.name),
          ),
        ),
        // Tap zones to switch photos.
        Row(children: [
          Expanded(
              child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _photo = (_photo - 1).clamp(0, photos.length - 1)))),
          Expanded(
              child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _photo = (_photo + 1).clamp(0, photos.length - 1)))),
        ]),
        if (photos.length > 1)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(
                photos.length,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _photo ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (p.boosted)
          Positioned(
            top: 24,
            right: 14,
            child: _pill(Icons.bolt_rounded, 'Boosted', Brand.gold),
          ),
        // Bottom info.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.online)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _pill(Icons.circle, 'Active now', Brand.green, small: true),
                        ),
                      Row(children: [
                        Flexible(
                          child: Text('${p.name}, ${p.age}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (p.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 24),
                        ],
                      ]),
                      if (p.job.isNotEmpty)
                        _line(Icons.work_rounded, p.job),
                      _line(Icons.location_on_rounded,
                          '${p.area} · ${km < 1 ? 'less than 1' : km.toStringAsFixed(0)} km away'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.interests
                            .take(3)
                            .map((i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(i,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.white24),
                  onPressed: widget.onInfo,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                ),
              ]),
            ),
          ),
        ),
        _stamp('LIKE', Brand.green, likeO, Alignment.topLeft, -0.35),
        _stamp('NOPE', Colors.redAccent, nopeO, Alignment.topRight, 0.35),
        _stamp('SUPER LIKE', Brand.blue, superO, Alignment.center, 0),
      ]),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ]),
      );

  Widget _pill(IconData icon, String text, Color color, {bool small = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.black45, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: small ? 9 : 15, color: color),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      );

  Widget _stamp(String text, Color c, double o, Alignment a, double angle) {
    if (o <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: a,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Opacity(
            opacity: o,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: c, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(text,
                    style: TextStyle(
                        color: c,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
