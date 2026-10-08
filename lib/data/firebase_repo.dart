import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models.dart';
import 'jaipur_areas.dart';
import 'repo.dart';

class FirebaseRepo implements Repo {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final Map<String, UserProfile> _cache = {};

  @override
  bool get isDemo => false;
  @override
  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static String matchIdFor(String a, String b) =>
      (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';

  @override
  Future<void> sendOtp(
    String phone, {
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function() onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        onAutoVerified();
      },
      verificationFailed: (e) => onError(e.message ?? e.code),
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<void> verifyOtp(String verificationId, String code) async {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: code);
    await _auth.signInWithCredential(cred);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final id = uid;
    if (id == null) return;
    await _users.doc(id).delete();
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  Future<UserProfile?> _profile(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final d = await _users.doc(id).get();
    if (!d.exists) return null;
    return _cache[id] = UserProfile.fromMap(id, d.data()!);
  }

  @override
  Future<UserProfile?> loadMe() async {
    final id = uid;
    if (id == null) return null;
    final d = await _users.doc(id).get();
    if (!d.exists) return null;
    await _users.doc(id).update({'lastActive': FieldValue.serverTimestamp()});
    return UserProfile.fromMap(id, d.data()!);
  }

  @override
  Future<void> saveMe(UserProfile me) async {
    await _users.doc(me.uid).set({
      ...me.toMap(),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String> uploadImage(String localPath, String folder) async {
    final ref = FirebaseStorage.instance
        .ref('users/$uid/$folder/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(
        File(localPath), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  @override
  Future<List<UserProfile>> fetchDeck(UserProfile me, Filters f) async {
    final swiped = await _users.doc(me.uid).collection('swipes').get();
    final skip = {me.uid, ...me.blocked, ...swiped.docs.map((d) => d.id)};
    final q = await _users
        .where('gender', whereIn: me.interestedIn)
        .limit(300)
        .get();
    final list = q.docs
        .map((d) => UserProfile.fromMap(d.id, d.data()))
        .where((p) =>
            !skip.contains(p.uid) &&
            !p.blocked.contains(me.uid) &&
            p.interestedIn.contains(me.gender) &&
            p.isComplete &&
            p.age >= f.minAge &&
            p.age <= f.maxAge &&
            distanceKm(me.area, p.area) <= f.maxKm &&
            (!f.verifiedOnly || p.verified))
        .toList();
    list.sort((a, b) {
      if (a.boosted != b.boosted) return a.boosted ? -1 : 1;
      return distanceKm(me.area, a.area).compareTo(distanceKm(me.area, b.area));
    });
    for (final p in list) {
      _cache[p.uid] = p;
    }
    return list;
  }

  @override
  Future<String?> swipe(
      UserProfile me, UserProfile other, SwipeType type) async {
    final batch = _db.batch();
    batch.set(_users.doc(me.uid).collection('swipes').doc(other.uid), {
      'type': type.name,
      'at': FieldValue.serverTimestamp(),
    });
    // Remove them from my "likes you" list once I have decided.
    batch.delete(_users.doc(me.uid).collection('likes').doc(other.uid));
    if (type != SwipeType.nope) {
      batch.set(_users.doc(other.uid).collection('likes').doc(me.uid), {
        'type': type.name,
        'at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    if (type == SwipeType.nope) return null;

    final theirs =
        await _users.doc(other.uid).collection('swipes').doc(me.uid).get();
    final liked = theirs.exists && theirs.data()?['type'] != 'nope';
    if (!liked) return null;
    final id = matchIdFor(me.uid, other.uid);
    await _db.collection('matches').doc(id).set({
      'users': [me.uid, other.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'unread': {me.uid: 0, other.uid: 0},
    });
    return id;
  }

  @override
  Future<void> undoSwipe(UserProfile other) async {
    final me = uid!;
    final batch = _db.batch();
    batch.delete(_users.doc(me).collection('swipes').doc(other.uid));
    batch.delete(_users.doc(other.uid).collection('likes').doc(me));
    await batch.commit();
  }

  @override
  Stream<List<MatchInfo>> matches() {
    final me = uid!;
    return _db
        .collection('matches')
        .where('users', arrayContains: me)
        .snapshots()
        .asyncMap((snap) async {
      final out = <MatchInfo>[];
      for (final d in snap.docs) {
        final m = d.data();
        final otherId =
            (m['users'] as List).cast<String>().firstWhere((u) => u != me);
        final other = await _profile(otherId);
        if (other == null) continue;
        out.add(MatchInfo(
          id: d.id,
          other: other,
          lastMessage: m['lastMessage'] ?? '',
          lastAt: (m['lastAt'] as Timestamp?)?.toDate(),
          unread: ((m['unread'] ?? {}) as Map)[me] ?? 0,
        ));
      }
      out.sort((a, b) => (b.lastAt ?? DateTime(2000))
          .compareTo(a.lastAt ?? DateTime(2000)));
      return out;
    });
  }

  @override
  Stream<List<UserProfile>> likesMe() {
    return _users.doc(uid).collection('likes').snapshots().asyncMap((s) async {
      final out = <UserProfile>[];
      for (final d in s.docs) {
        final p = await _profile(d.id);
        if (p != null) out.add(p);
      }
      return out;
    });
  }

  @override
  Stream<List<ChatMessage>> messages(String matchId) => _db
      .collection('matches')
      .doc(matchId)
      .collection('messages')
      .orderBy('at', descending: true)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final m = d.data();
            return ChatMessage(
              id: d.id,
              from: m['from'] ?? '',
              text: m['text'] ?? '',
              imageUrl: m['imageUrl'],
              at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
              read: m['read'] ?? false,
            );
          }).toList());

  @override
  Future<void> sendMessage(String matchId,
      {String text = '', String? imageUrl}) async {
    final me = uid!;
    final ref = _db.collection('matches').doc(matchId);
    final other = matchId.split('_').firstWhere((u) => u != me);
    final batch = _db.batch();
    batch.set(ref.collection('messages').doc(), {
      'from': me,
      'text': text,
      'imageUrl': imageUrl,
      'at': FieldValue.serverTimestamp(),
      'read': false,
    });
    batch.update(ref, {
      'lastMessage': imageUrl != null ? '📷 Photo' : text,
      'lastAt': FieldValue.serverTimestamp(),
      'unread.$other': FieldValue.increment(1),
      'typing.$me': false,
    });
    await batch.commit();
  }

  @override
  Future<void> markRead(String matchId) async {
    final me = uid!;
    final ref = _db.collection('matches').doc(matchId);
    await ref.update({'unread.$me': 0});
    final other = matchId.split('_').firstWhere((u) => u != me);
    final unread = await ref
        .collection('messages')
        .where('from', isEqualTo: other)
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> setTyping(String matchId, bool typing) => _db
      .collection('matches')
      .doc(matchId)
      .update({'typing.$uid': typing});

  @override
  Stream<bool> otherTyping(String matchId, String otherUid) => _db
      .collection('matches')
      .doc(matchId)
      .snapshots()
      .map((d) => ((d.data()?['typing'] ?? {}) as Map)[otherUid] == true);

  @override
  Future<void> unmatch(String matchId) =>
      _db.collection('matches').doc(matchId).delete();

  @override
  Future<void> block(UserProfile me, String otherUid) async {
    me.blocked.add(otherUid);
    await _users.doc(me.uid).update({
      'blocked': FieldValue.arrayUnion([otherUid])
    });
    try {
      await unmatch(matchIdFor(me.uid, otherUid));
    } catch (_) {
      // No match existed with this person.
    }
  }

  @override
  Future<void> report(String otherUid, String reason, String details) =>
      _db.collection('reports').add({
        'by': uid,
        'against': otherUid,
        'reason': reason,
        'details': details,
        'at': FieldValue.serverTimestamp(),
        'status': 'open',
      });
}
