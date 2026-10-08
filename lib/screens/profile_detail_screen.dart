import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/jaipur_areas.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/safety.dart';

/// Full profile. With [showActions] it pops with the chosen SwipeType.
class ProfileDetailScreen extends StatefulWidget {
  final UserProfile p;
  final bool showActions;
  final bool isMe;
  const ProfileDetailScreen(
      {super.key, required this.p, this.showActions = false, this.isMe = false});
  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final photos = p.photos.isEmpty ? <String?>[null] : p.photos;
    final h = MediaQuery.of(context).size.height;
    final km = app.me == null || widget.isMe ? 0 : distanceKm(app.me!.area, p.area);
    return Scaffold(
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: h * 0.62,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (!widget.isMe)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        final blocked = await showSafetyMenu(context, p);
                        if (blocked && context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _photo = i),
                  itemBuilder: (_, i) => Hero(
                    tag: 'photo_${p.uid}_$i',
                    child: Photo(photos[i], name: p.name),
                  ),
                ),
                if (photos.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.all(3),
                          width: i == _photo ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _photo ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(children: [
                  Flexible(
                    child: Text('${p.name}, ${p.age}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  if (p.verified) ...[
                    const SizedBox(width: 8),
                    const VerifiedBadge(size: 26),
                  ],
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (p.job.isNotEmpty) _info(Icons.work_rounded, p.job),
                  if (p.education.isNotEmpty) _info(Icons.school_rounded, p.education),
                  _info(Icons.location_on_rounded,
                      widget.isMe ? p.area : '${p.area} · ${km.toStringAsFixed(0)} km'),
                  if (p.heightCm != null) _info(Icons.height_rounded, '${p.heightCm} cm'),
                  _info(Icons.favorite_border_rounded, p.lookingFor),
                ]),
                if (p.bio.isNotEmpty) ...[
                  _heading('About'),
                  Text(p.bio, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
                ...p.prompts.entries.map((e) => Container(
                      margin: const EdgeInsets.only(top: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Brand.pink.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.key,
                            style: const TextStyle(
                                color: Brand.pink, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(e.value,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
                      ]),
                    )),
                if (p.interests.isNotEmpty) ...[
                  _heading('Interests'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.interests.map((i) {
                      final shared = !widget.isMe && (app.me?.interests.contains(i) ?? false);
                      return Chip(
                        label: Text(i),
                        avatar: shared
                            ? const Icon(Icons.check_circle, size: 18, color: Brand.pink)
                            : null,
                        side: BorderSide(
                            color: shared ? Brand.pink : Theme.of(context).dividerColor),
                      );
                    }).toList(),
                  ),
                ],
              ]),
            ),
          ),
        ]),
        if (widget.showActions)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _action(Icons.close_rounded, Colors.redAccent, SwipeType.nope),
              const SizedBox(width: 22),
              _action(Icons.star_rounded, Brand.blue, SwipeType.superLike, size: 54),
              const SizedBox(width: 22),
              _action(Icons.favorite_rounded, Brand.green, SwipeType.like),
            ]),
          ),
      ]),
    );
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 10),
        child: Text(t,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  Widget _info(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: Brand.pink),
          const SizedBox(width: 6),
          Text(t),
        ]),
      );

  Widget _action(IconData icon, Color c, SwipeType t, {double size = 64}) =>
      GestureDetector(
        onTap: () => Navigator.pop(context, t),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withOpacity(0.35), blurRadius: 18)],
          ),
          child: Icon(icon, color: c, size: size * 0.5),
        ),
      );
}
