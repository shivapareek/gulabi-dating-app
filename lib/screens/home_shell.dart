import 'package:flutter/material.dart';

import '../data/repo.dart';
import '../models.dart';
import '../theme.dart';
import 'chats_screen.dart';
import 'discover_screen.dart';
import 'likes_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  // Each listener gets its own stream (the streams are single-subscription).
  late final Stream<List<MatchInfo>> _matches = Repo.instance.matches();
  late final Stream<List<MatchInfo>> _matchesBadge = Repo.instance.matches();
  late final Stream<List<UserProfile>> _likes = Repo.instance.likesMe();
  late final Stream<List<UserProfile>> _likesBadge = Repo.instance.likesMe();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        const DiscoverScreen(),
        LikesScreen(likes: _likes),
        ChatsScreen(matches: _matches),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          height: 66,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1C1620) : Colors.white,
            borderRadius: BorderRadius.circular(33),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(children: [
            _item(0, Icons.local_fire_department_rounded, 'Discover'),
            StreamBuilder<List<UserProfile>>(
              stream: _likesBadge,
              builder: (_, s) =>
                  _item(1, Icons.favorite_rounded, 'Likes', badge: s.data?.length ?? 0),
            ),
            StreamBuilder<List<MatchInfo>>(
              stream: _matchesBadge,
              builder: (_, s) => _item(2, Icons.chat_bubble_rounded, 'Chats',
                  badge: (s.data ?? []).fold(0, (a, m) => a + m.unread)),
            ),
            _item(3, Icons.person_rounded, 'Profile'),
          ]),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, {int badge = 0}) {
    final sel = _tab == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = i),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: sel ? 14 : 8, vertical: 9),
            decoration: BoxDecoration(
              gradient: sel ? Brand.gradient : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Icon(icon,
                    size: 24, color: sel ? Colors.white : Theme.of(context).hintColor),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                child: sel
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
