import '../models.dart';

/// Everything the UI needs from the backend. FirebaseRepo is the live
/// backend; DemoRepo keeps data in memory so the app can be previewed
/// before Firebase is configured.
abstract class Repo {
  static late Repo instance;

  bool get isDemo;
  String? get uid;

  Future<void> sendOtp(
    String phone, {
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function() onAutoVerified,
  });
  Future<void> verifyOtp(String verificationId, String code);
  Future<void> signOut();
  Future<void> deleteAccount();

  Future<UserProfile?> loadMe();
  Future<void> saveMe(UserProfile me);

  /// Uploads a local image file and returns its public URL.
  Future<String> uploadImage(String localPath, String folder);

  Future<List<UserProfile>> fetchDeck(UserProfile me, Filters f);

  /// Records a swipe; returns the match id when it created a match.
  Future<String?> swipe(UserProfile me, UserProfile other, SwipeType type);
  Future<void> undoSwipe(UserProfile other);

  Stream<List<MatchInfo>> matches();
  Stream<List<UserProfile>> likesMe();

  Stream<List<ChatMessage>> messages(String matchId);
  Future<void> sendMessage(String matchId, {String text = '', String? imageUrl});
  Future<void> markRead(String matchId);
  Future<void> setTyping(String matchId, bool typing);
  Stream<bool> otherTyping(String matchId, String otherUid);

  Future<void> unmatch(String matchId);
  Future<void> block(UserProfile me, String otherUid);
  Future<void> report(String otherUid, String reason, String details);
}
