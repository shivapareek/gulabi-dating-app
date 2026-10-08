import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/swipe_card.dart';
import 'filters_sheet.dart';
import 'match_screen.dart';
import 'premium_screen.dart';
import 'profile_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  List<UserProfile> _deck = [];
  bool _loading = true;
  UserProfile? _lastSwiped;
  Offset _drag = Offset.zero;
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  Animation<Offset>? _flyAnim;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_flyAnim != null) setState(() => _drag = _flyAnim!.value);
    });
    _load();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = app.me;
    if (me == null) return;
    setState(() => _loading = true);
    try {
      final d = await Repo.instance.fetchDeck(me, app.filters);
      if (mounted) setState(() => _deck = d);
    } catch (e) {
      if (mounted) toast(context, 'Could not load profiles: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _animateTo(Offset target) async {
    _flyAnim = Tween(begin: _drag, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    await _anim.forward(from: 0);
    _flyAnim = null;
  }

  Future<void> _swipe(SwipeType type) async {
    if (_deck.isEmpty || _anim.isAnimating) return;
    if (type == SwipeType.like && !app.canLike) {
      await _animateTo(Offset.zero);
      if (mounted) _upsell('You are out of free likes for today');
      return;
    }
    if (type == SwipeType.superLike && !app.canSuperLike) {
      await _animateTo(Offset.zero);
      if (mounted) _upsell('Get more Super Likes with Gulabi Gold');
      return;
    }
    final w = MediaQuery.of(context).size.width;
    final target = switch (type) {
      SwipeType.like => Offset(w * 1.5, _drag.dy),
      SwipeType.nope => Offset(-w * 1.5, _drag.dy),
      SwipeType.superLike => Offset(_drag.dx, -w * 2),
    };
    await _animateTo(target);
    final other = _deck.first;
    setState(() {
      _deck.removeAt(0);
      _drag = Offset.zero;
      _lastSwiped = other;
    });
    app.countSwipe(type);
    try {
      final matchId = await Repo.instance.swipe(app.me!, other, type);
      if (matchId != null && mounted) {
        Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) =>
              MatchScreen(other: other, matchId: matchId),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      }
    } catch (e) {
      if (mounted) toast(context, 'Swipe failed: $e');
    }
    if (_deck.length < 3) _load();
  }

  Future<void> _rewind() async {
    if (!app.premium) {
      _upsell('Rewind your last swipe with Gulabi Gold');
      return;
    }
    final p = _lastSwiped;
    if (p == null) {
      toast(context, 'Nothing to rewind');
      return;
    }
    await Repo.instance.undoSwipe(p);
    setState(() {
      _deck.insert(0, p);
      _lastSwiped = null;
    });
  }

  Future<void> _boost() async {
    if (!app.premium) {
      _upsell('Boost puts you at the top in Jaipur for 30 minutes');
      return;
    }
    final me = app.me!;
    if (me.boosted) {
      toast(context, 'Boost is already active');
      return;
    }
    me.boostUntil = DateTime.now().add(const Duration(minutes: 30));
    await app.saveMe(me);
    if (mounted) toast(context, '⚡ Boost active for 30 minutes');
  }

  void _upsell(String reason) => Navigator.of(context)
      .push(fadeRoute(PremiumScreen(reason: reason)));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
          child: Row(children: [
            const LogoMark(size: 34),
            const SizedBox(width: 10),
            Text('Gulabi',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            if (Repo.instance.isDemo)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Chip(label: Text('Demo'), visualDensity: VisualDensity.compact),
              ),
            IconButton(
              tooltip: 'Filters',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () async {
                final changed = await showFiltersSheet(context);
                if (changed == true) _load();
              },
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _loading && _deck.isEmpty
                ? const _Radar()
                : _deck.isEmpty
                    ? _empty()
                    : Stack(children: [
                        if (_deck.length > 1)
                          Positioned.fill(
                            child: Transform.scale(
                              scale: 0.94 +
                                  0.06 *
                                      min(1, _drag.distance / (size.width * 0.5)),
                              child: SwipeCard(
                                key: ValueKey(_deck[1].uid),
                                p: _deck[1],
                                onInfo: () {},
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (d) =>
                                setState(() => _drag += d.delta),
                            onPanEnd: (d) {
                              final vx = d.velocity.pixelsPerSecond.dx;
                              if (_drag.dx > size.width * 0.28 || vx > 900) {
                                _swipe(SwipeType.like);
                              } else if (_drag.dx < -size.width * 0.28 ||
                                  vx < -900) {
                                _swipe(SwipeType.nope);
                              } else if (_drag.dy < -size.height * 0.18) {
                                _swipe(SwipeType.superLike);
                              } else {
                                _animateTo(Offset.zero);
                              }
                            },
                            child: Transform.translate(
                              offset: _drag,
                              child: Transform.rotate(
                                angle: _drag.dx / size.width * 0.35,
                                child: SwipeCard(
                                  key: ValueKey(_deck.first.uid),
                                  p: _deck.first,
                                  drag: Offset(
                                      _drag.dx / (size.width * 0.3),
                                      min(0, _drag.dy) / (size.height * 0.2)),
                                  onInfo: () => _openDetail(_deck.first),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _RoundBtn(Icons.replay_rounded, Brand.gold, 48, _rewind),
            _RoundBtn(Icons.close_rounded, Colors.redAccent, 62,
                () => _swipe(SwipeType.nope)),
            _RoundBtn(Icons.star_rounded, Brand.blue, 48,
                () => _swipe(SwipeType.superLike)),
            _RoundBtn(Icons.favorite_rounded, Brand.green, 62,
                () => _swipe(SwipeType.like)),
            _RoundBtn(Icons.bolt_rounded, const Color(0xFF9B5CFF), 48, _boost),
          ]),
        ),
        const SizedBox(height: 70),
      ]),
    );
  }

  Future<void> _openDetail(UserProfile p) async {
    final result = await Navigator.of(context).push<SwipeType>(
        fadeRoute(ProfileDetailScreen(p: p, showActions: true)));
    if (result != null) _swipe(result);
  }

  Widget _empty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.travel_explore_rounded, size: 72, color: Brand.pink),
          const SizedBox(height: 16),
          Text('No one new nearby right now',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Try widening your filters or check back soon.',
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ]),
      );
}

class _RoundBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _RoundBtn(this.icon, this.color, this.size, this.onTap);
  @override
  State<_RoundBtn> createState() => _RoundBtnState();
}

class _RoundBtnState extends State<_RoundBtn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.85 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1C1620) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size * 0.5),
        ),
      ),
    );
  }
}

/// Pulsing radar shown while profiles load.
class _Radar extends StatefulWidget {
  const _Radar();
  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          for (var i = 0; i < 3; i++)
            Builder(builder: (_) {
              final v = (_c.value + i / 3) % 1;
              return Container(
                width: 80 + 220 * v,
                height: 80 + 220 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.pink.withOpacity(0.25 * (1 - v)),
                ),
              );
            }),
          Avatar(app.me?.photos.firstOrNull, name: app.me?.name ?? '', size: 90),
        ]),
      ),
    );
  }
}
