import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  final Stream<List<MatchInfo>> matches;
  const ChatsScreen({super.key, required this.matches});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _query = '';

  void _open(MatchInfo m) => Navigator.of(context)
      .push(fadeRoute(ChatScreen(matchId: m.id, other: m.other)));

  String _when(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    if (now.difference(t).inDays == 0 && now.day == t.day) {
      return DateFormat('h:mm a').format(t);
    }
    if (now.difference(t).inDays < 7) return DateFormat('EEE').format(t);
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<MatchInfo>>(
        stream: widget.matches,
        builder: (context, s) {
          final all = s.data ?? [];
          final fresh = all.where((m) => m.lastMessage.isEmpty).toList();
          final convos = all
              .where((m) =>
                  m.lastMessage.isNotEmpty &&
                  m.other.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Chats',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search matches',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Text('New matches',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                height: 112,
                child: fresh.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Your new matches will show up here',
                            style: TextStyle(color: Theme.of(context).hintColor)),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: fresh.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) {
                          final m = fresh[i];
                          return GestureDetector(
                            onTap: () => _open(m),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    gradient: Brand.gradient, shape: BoxShape.circle),
                                child: Avatar(m.other.photos.firstOrNull,
                                    name: m.other.name, size: 72),
                              ),
                              const SizedBox(height: 6),
                              Text(m.other.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('Messages',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (convos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Say hi to a match to start a conversation 👋',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                ),
              ...convos.map((m) => ListTile(
                    onTap: () => _open(m),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Avatar(m.other.photos.firstOrNull,
                        name: m.other.name, size: 56, online: m.other.online),
                    title: Row(children: [
                      Text(m.other.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (m.other.verified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 16),
                      ],
                    ]),
                    subtitle: Text(m.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight:
                                m.unread > 0 ? FontWeight.w700 : FontWeight.normal)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_when(m.lastAt),
                            style: TextStyle(
                                fontSize: 12, color: Theme.of(context).hintColor)),
                        const SizedBox(height: 4),
                        if (m.unread > 0)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                gradient: Brand.gradient,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('${m.unread}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
