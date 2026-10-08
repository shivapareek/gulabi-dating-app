import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/repo.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/safety.dart';
import 'profile_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final UserProfile other;
  const ChatScreen({super.key, required this.matchId, required this.other});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  late final Stream<List<ChatMessage>> _messages =
      Repo.instance.messages(widget.matchId);
  late final Stream<bool> _typing =
      Repo.instance.otherTyping(widget.matchId, widget.other.uid);
  // Broadcast: the list item holding it can be rebuilt after scrolling.
  late final Stream<bool> _typingInList = Repo.instance
      .otherTyping(widget.matchId, widget.other.uid)
      .asBroadcastStream();
  Timer? _typingTimer;
  bool _sendingImage = false;
  int _lastCount = 0;

  static const _icebreakers = [
    'Hi! Your profile made me smile 😊',
    'Best chai spot in Jaipur? Go!',
    'Nahargarh sunset or Jal Mahal at night?',
    'What does your perfect weekend look like?',
  ];

  String get _me => Repo.instance.uid ?? 'me';

  @override
  void initState() {
    super.initState();
    Repo.instance.markRead(widget.matchId).catchError((_) {});
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    Repo.instance.setTyping(widget.matchId, false).catchError((_) {});
    super.dispose();
  }

  void _onChanged(String v) {
    if (_typingTimer == null) {
      Repo.instance.setTyping(widget.matchId, true).catchError((_) {});
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _typingTimer = null;
      Repo.instance.setTyping(widget.matchId, false).catchError((_) {});
    });
    setState(() {});
  }

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _text.text).trim();
    if (t.isEmpty) return;
    _text.clear();
    setState(() {});
    try {
      await Repo.instance.sendMessage(widget.matchId, text: t);
    } catch (e) {
      if (mounted) toast(context, 'Message not sent: $e');
    }
  }

  Future<void> _sendImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1280);
    if (x == null) return;
    setState(() => _sendingImage = true);
    try {
      final url = await Repo.instance.uploadImage(x.path, 'chat');
      await Repo.instance.sendMessage(widget.matchId, imageUrl: url);
    } catch (e) {
      if (mounted) toast(context, 'Photo not sent: $e');
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  Future<void> _menu(String v) async {
    if (v == 'profile') {
      Navigator.of(context).push(fadeRoute(ProfileDetailScreen(p: widget.other)));
    } else if (v == 'unmatch') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Unmatch ${widget.other.name}?'),
          content: const Text('This conversation will be deleted for both of you.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unmatch')),
          ],
        ),
      );
      if (ok == true) {
        await Repo.instance.unmatch(widget.matchId);
        if (mounted) Navigator.pop(context);
      }
    } else if (v == 'safety') {
      final blocked = await showSafetyMenu(context, widget.other);
      if (blocked && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.other;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _menu('profile'),
          child: Row(children: [
            Avatar(o.photos.firstOrNull, name: o.name, size: 40, online: o.online),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(o.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  if (o.verified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 16)],
                ]),
                StreamBuilder<bool>(
                  stream: _typing,
                  builder: (_, s) => Text(
                    s.data == true ? 'typing…' : (o.online ? 'Active now' : o.area),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: s.data == true ? Brand.pink : Theme.of(context).hintColor),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('View profile')),
              PopupMenuItem(value: 'unmatch', child: Text('Unmatch')),
              PopupMenuItem(value: 'safety', child: Text('Report / Block')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _messages,
            builder: (context, s) {
              final msgs = s.data ?? [];
              if (msgs.length != _lastCount) {
                if (msgs.isNotEmpty && msgs.first.from != _me) {
                  Repo.instance.markRead(widget.matchId).catchError((_) {});
                }
                _lastCount = msgs.length;
              }
              if (msgs.isEmpty) return _emptyChat();
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                itemCount: msgs.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return StreamBuilder<bool>(
                      stream: _typingInList,
                      builder: (_, t) => AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: t.data == true ? const _TypingBubble() : const SizedBox.shrink(),
                      ),
                    );
                  }
                  final m = msgs[i - 1];
                  final mine = m.from == _me;
                  final showTime = i == msgs.length ||
                      msgs[i].at.difference(m.at).inMinutes.abs() > 30;
                  return Column(children: [
                    if (showTime)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(DateFormat('d MMM, h:mm a').format(m.at),
                            style: TextStyle(
                                fontSize: 11, color: Theme.of(context).hintColor)),
                      ),
                    _Bubble(m: m, mine: mine, isLatestMine: mine && i == 1),
                  ]);
                },
              );
            },
          ),
        ),
        _composer(),
      ]),
    );
  }

  Widget _emptyChat() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          Center(
            child: Avatar(widget.other.photos.firstOrNull,
                name: widget.other.name, size: 110),
          ),
          const SizedBox(height: 16),
          Text('You matched with ${widget.other.name}!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Break the ice with one of these:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 18),
          ..._icebreakers.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    side: BorderSide(color: Brand.pink.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _send(t),
                  child: Text(t),
                ),
              )),
        ],
      );

  Widget _composer() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Row(children: [
            IconButton(
              onPressed: _sendingImage ? null : _sendImage,
              icon: _sendingImage
                  ? const SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.photo_rounded, color: Brand.pink),
            ),
            Expanded(
              child: TextField(
                controller: _text,
                onChanged: _onChanged,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: _text.text.trim().isEmpty ? 0.85 : 1,
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      gradient: Brand.gradient, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  final bool mine;
  final bool isLatestMine;
  const _Bubble({required this.m, required this.mine, required this.isLatestMine});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74),
              padding: m.imageUrl != null
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                gradient: mine ? Brand.gradient : null,
                color: mine ? null : (dark ? const Color(0xFF241C29) : Colors.white),
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: m.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                          width: 220, height: 280, child: Photo(m.imageUrl, name: '')),
                    )
                  : Text(m.text,
                      style: TextStyle(
                          fontSize: 15.5, color: mine ? Colors.white : null)),
            ),
            if (isLatestMine)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(m.read ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 15, color: m.read ? Brand.blue : Theme.of(context).hintColor),
                  const SizedBox(width: 3),
                  Text(m.read ? 'Seen' : 'Sent',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF241C29) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final v = ((_c.value * 3 - i) % 3);
              final up = v < 1 ? v : 0.0;
              return Transform.translate(
                offset: Offset(0, -4 * (up < 0.5 ? up * 2 : (1 - up) * 2)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: Brand.pink.withOpacity(0.7), shape: BoxShape.circle),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
