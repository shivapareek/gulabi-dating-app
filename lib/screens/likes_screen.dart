import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'match_screen.dart';
import 'premium_screen.dart';
import 'profile_detail_screen.dart';

class LikesScreen extends StatelessWidget {
  final Stream<List<UserProfile>> likes;
  const LikesScreen({super.key, required this.likes});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) => StreamBuilder<List<UserProfile>>(
          stream: likes,
          builder: (context, s) {
            final list = s.data ?? [];
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text('Likes',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    list.isEmpty
                        ? 'No new likes yet. Complete your profile to get noticed.'
                        : '${list.length} ${list.length == 1 ? 'person likes' : 'people like'} you',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ),
              if (!app.premium && list.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: GradientButton('See who likes you',
                        icon: Icons.lock_open_rounded,
                        gradient: Brand.goldGradient,
                        onTap: () => Navigator.of(context).push(fadeRoute(
                            const PremiumScreen(
                                reason: 'Match instantly with people who already like you')))),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _LikeTile(p: list[i], locked: !app.premium),
                    childCount: list.length,
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _LikeTile extends StatelessWidget {
  final UserProfile p;
  final bool locked;
  const _LikeTile({required this.p, required this.locked});

  Future<void> _open(BuildContext context) async {
    if (locked) {
      Navigator.of(context).push(fadeRoute(const PremiumScreen(
          reason: 'Match instantly with people who already like you')));
      return;
    }
    final t = await Navigator.of(context)
        .push<SwipeType>(fadeRoute(ProfileDetailScreen(p: p, showActions: true)));
    if (t == null || !context.mounted) return;
    final matchId = await Repo.instance.swipe(app.me!, p, t);
    if (matchId != null && context.mounted) {
      Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => MatchScreen(other: p, matchId: matchId),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: locked ? 18 : 0, sigmaY: locked ? 18 : 0),
            child: Photo(p.photos.firstOrNull, name: p.name),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(locked ? '••••, ${p.age}' : '${p.name}, ${p.age}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                if (p.verified && !locked) const VerifiedBadge(size: 18),
              ]),
            ),
          ),
          if (locked)
            const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 34)),
        ]),
      ),
    );
  }
}
