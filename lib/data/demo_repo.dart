import 'dart:async';
import 'dart:math';

import '../models.dart';
import 'jaipur_areas.dart';
import 'repo.dart';

/// In-memory backend for previewing the app before Firebase is configured.
/// OTP is always 123456. Demo people like you back and reply in chat.
class DemoRepo implements Repo {
  final _rand = Random();
  String? _uid;
  UserProfile? _me;
  final List<UserProfile> _people = _seed();
  final Map<String, SwipeType> _swipes = {};
  final Map<String, List<ChatMessage>> _chats = {};
  final Map<String, UserProfile> _matchOther = {};
  final Map<String, int> _unread = {};
  final Map<String, bool> _typing = {};
  final List<UserProfile> _likesMe = [];
  final _changes = StreamController<void>.broadcast();

  DemoRepo() {
    _likesMe.addAll(_people.where((p) => p.uid.hashCode % 3 == 0).take(4));
  }

  @override
  bool get isDemo => true;
  @override
  String? get uid => _uid;

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void _notify() => _changes.add(null);

  @override
  Future<void> sendOtp(String phone,
      {required void Function(String) onCodeSent,
      required void Function(String) onError,
      required void Function() onAutoVerified}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    onCodeSent('demo');
  }

  @override
  Future<void> verifyOtp(String verificationId, String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (code != '123456') throw Exception('Wrong code. Demo code is 123456');
    _uid = 'me';
  }

  @override
  Future<void> signOut() async => _uid = null;

  @override
  Future<void> deleteAccount() async {
    _me = null;
    _uid = null;
  }

  @override
  Future<UserProfile?> loadMe() async => _me;

  @override
  Future<void> saveMe(UserProfile me) async => _me = me;

  @override
  Future<String> uploadImage(String localPath, String folder) async =>
      'file://$localPath';

  @override
  Future<List<UserProfile>> fetchDeck(UserProfile me, Filters f) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _people
        .where((p) =>
            !_swipes.containsKey(p.uid) &&
            !me.blocked.contains(p.uid) &&
            me.interestedIn.contains(p.gender) &&
            p.age >= f.minAge &&
            p.age <= f.maxAge &&
            distanceKm(me.area, p.area) <= f.maxKm &&
            (!f.verifiedOnly || p.verified))
        .toList();
  }

  @override
  Future<String?> swipe(
      UserProfile me, UserProfile other, SwipeType type) async {
    _swipes[other.uid] = type;
    _likesMe.removeWhere((p) => p.uid == other.uid);
    _notify();
    final likedBack = _rand.nextDouble() < 0.5 ||
        type == SwipeType.superLike ||
        other.uid.hashCode % 3 == 0;
    if (type == SwipeType.nope || !likedBack) return null;
    final id = 'm_${other.uid}';
    _matchOther[id] = other;
    _chats[id] = [];
    _unread[id] = 0;
    _notify();
    return id;
  }

  @override
  Future<void> undoSwipe(UserProfile other) async {
    _swipes.remove(other.uid);
    _notify();
  }

  @override
  Stream<List<MatchInfo>> matches() => _live(() {
        final list = _matchOther.entries.map((e) {
          final msgs = _chats[e.key] ?? [];
          final last = msgs.isEmpty ? null : msgs.first;
          return MatchInfo(
            id: e.key,
            other: e.value,
            lastMessage: last == null
                ? ''
                : (last.imageUrl != null ? '📷 Photo' : last.text),
            lastAt: last?.at,
            unread: _unread[e.key] ?? 0,
          );
        }).toList();
        list.sort((a, b) => (b.lastAt ?? DateTime(2000))
            .compareTo(a.lastAt ?? DateTime(2000)));
        return list;
      });

  @override
  Stream<List<UserProfile>> likesMe() => _live(() => List.of(_likesMe));

  @override
  Stream<List<ChatMessage>> messages(String matchId) =>
      _live(() => List.of(_chats[matchId] ?? []));

  static const _replies = [
    'Haha that is so true 😄',
    'Weekend pe free ho? Coffee at Tapri? ☕',
    'Mujhe bhi! Which one is your favourite?',
    'Tell me more about yourself 😊',
    'Pink City sunsets from Nahargarh are the best 🌅',
    'Achha! Kab se Jaipur mein ho?',
  ];

  @override
  Future<void> sendMessage(String matchId,
      {String text = '', String? imageUrl}) async {
    _chats[matchId]!.insert(
        0,
        ChatMessage(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            from: 'me',
            text: text,
            imageUrl: imageUrl,
            at: DateTime.now()));
    _notify();
    final other = _matchOther[matchId]!;
    Future.delayed(const Duration(seconds: 1), () {
      _typing[matchId] = true;
      // Mark my messages as read by them.
      _chats[matchId] = _chats[matchId]!
          .map((m) => m.from == 'me'
              ? ChatMessage(
                  id: m.id,
                  from: m.from,
                  text: m.text,
                  imageUrl: m.imageUrl,
                  at: m.at,
                  read: true)
              : m)
          .toList();
      _notify();
    });
    Future.delayed(const Duration(seconds: 3), () {
      _typing[matchId] = false;
      _chats[matchId]?.insert(
          0,
          ChatMessage(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              from: other.uid,
              text: _replies[_rand.nextInt(_replies.length)],
              at: DateTime.now()));
      _unread[matchId] = (_unread[matchId] ?? 0) + 1;
      _notify();
    });
  }

  @override
  Future<void> markRead(String matchId) async {
    _unread[matchId] = 0;
    _notify();
  }

  @override
  Future<void> setTyping(String matchId, bool typing) async {}

  @override
  Stream<bool> otherTyping(String matchId, String otherUid) =>
      _live(() => _typing[matchId] ?? false);

  @override
  Future<void> unmatch(String matchId) async {
    _matchOther.remove(matchId);
    _chats.remove(matchId);
    _notify();
  }

  @override
  Future<void> block(UserProfile me, String otherUid) async {
    me.blocked.add(otherUid);
    await unmatch('m_$otherUid');
    _likesMe.removeWhere((p) => p.uid == otherUid);
    _notify();
  }

  @override
  Future<void> report(String otherUid, String reason, String details) async {}

  static List<UserProfile> _seed() {
    final r = Random(7);
    final areas = jaipurAreas.keys.toList();
    const women = [
      'Ananya', 'Priya', 'Riya', 'Kavya', 'Ishita', 'Aditi', 'Sneha',
      'Meera', 'Tanvi', 'Nidhi', 'Pooja', 'Simran',
    ];
    const men = [
      'Arjun', 'Rohan', 'Vikram', 'Kunal', 'Aditya', 'Karan', 'Rahul',
      'Yash', 'Dev', 'Siddharth', 'Manav', 'Harsh',
    ];
    const jobs = [
      'Software Engineer', 'Architect', 'Doctor', 'CA', 'Designer',
      'Entrepreneur', 'Teacher', 'Lawyer', 'Photographer', 'Marketing',
    ];
    const bios = [
      'Chai over coffee, always. Looking for someone to explore Jaipur cafes with.',
      'Weekend trekker, weekday overthinker. Swipe right if you love dal baati.',
      'Sunsets at Nahargarh and long drives are my thing.',
      'Bookworm with a soft spot for old havelis and new music.',
      'Gym in the morning, Netflix at night. Simple person, big dreams.',
      'Here for real conversations, not just small talk.',
    ];
    UserProfile make(String name, String gender, int i) {
      final interests = (List.of(allInterests)..shuffle(r)).take(5).toList();
      return UserProfile(
        uid: '${gender[0]}$i',
        name: name,
        dob: DateTime(1990 + r.nextInt(14), 1 + r.nextInt(12), 1 + r.nextInt(27)),
        gender: gender,
        interestedIn: [gender == 'Man' ? 'Woman' : 'Man'],
        area: areas[r.nextInt(areas.length)],
        bio: bios[r.nextInt(bios.length)],
        job: jobs[r.nextInt(jobs.length)],
        education: r.nextBool() ? 'MNIT Jaipur' : 'University of Rajasthan',
        heightCm: gender == 'Man' ? 168 + r.nextInt(18) : 152 + r.nextInt(18),
        lookingFor: ['Relationship', 'Something casual', 'Friends', 'Not sure'][r.nextInt(4)],
        interests: interests,
        prompts: {
          allPrompts[r.nextInt(3)]: 'Pyaaz kachori at Rawat, then a walk around Hawa Mahal.',
          allPrompts[3 + r.nextInt(3)]: 'Honest conversations and good food.',
        },
        photos: const [],
        verified: r.nextBool(),
        lastActive: DateTime.now().subtract(Duration(minutes: r.nextInt(120))),
      );
    }

    return [
      for (var i = 0; i < women.length; i++) make(women[i], 'Woman', i),
      for (var i = 0; i < men.length; i++) make(men[i], 'Man', i),
    ];
  }
}
