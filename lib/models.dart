class UserProfile {
  String uid;
  String name;
  DateTime? dob;
  String gender; // 'Man' | 'Woman' | 'Other'
  List<String> interestedIn;
  String area;
  String bio;
  String job;
  String education;
  int? heightCm;
  String lookingFor; // 'Relationship' | 'Something casual' | 'Friends' | 'Not sure'
  List<String> interests;
  Map<String, String> prompts;
  List<String> photos;
  bool verified;
  String verificationStatus; // none | pending | approved
  String selfie;
  bool premium;
  DateTime? boostUntil;
  List<String> blocked;
  DateTime? lastActive;

  UserProfile({
    required this.uid,
    this.name = '',
    this.dob,
    this.gender = 'Woman',
    List<String>? interestedIn,
    this.area = 'C-Scheme',
    this.bio = '',
    this.job = '',
    this.education = '',
    this.heightCm,
    this.lookingFor = 'Relationship',
    List<String>? interests,
    Map<String, String>? prompts,
    List<String>? photos,
    this.verified = false,
    this.verificationStatus = 'none',
    this.selfie = '',
    this.premium = false,
    this.boostUntil,
    List<String>? blocked,
    this.lastActive,
  })  : interestedIn = interestedIn ?? ['Man'],
        interests = interests ?? [],
        prompts = prompts ?? {},
        photos = photos ?? [],
        blocked = blocked ?? [];

  int get age {
    if (dob == null) return 0;
    final now = DateTime.now();
    var a = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      a--;
    }
    return a;
  }

  bool get isComplete => name.isNotEmpty && dob != null && photos.isNotEmpty;
  bool get boosted => boostUntil != null && boostUntil!.isAfter(DateTime.now());
  bool get online =>
      lastActive != null &&
      DateTime.now().difference(lastActive!).inMinutes < 5;

  Map<String, dynamic> toMap() => {
        'name': name,
        'dob': dob?.millisecondsSinceEpoch,
        'gender': gender,
        'interestedIn': interestedIn,
        'area': area,
        'bio': bio,
        'job': job,
        'education': education,
        'heightCm': heightCm,
        'lookingFor': lookingFor,
        'interests': interests,
        'prompts': prompts,
        'photos': photos,
        'verified': verified,
        'verificationStatus': verificationStatus,
        'selfie': selfie,
        'premium': premium,
        'boostUntil': boostUntil?.millisecondsSinceEpoch,
        'blocked': blocked,
      };

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try {
      return (v as dynamic).toDate() as DateTime; // Firestore Timestamp
    } catch (_) {
      return null;
    }
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) =>
      UserProfile(
        uid: uid,
        name: m['name'] ?? '',
        dob: _dt(m['dob']),
        gender: m['gender'] ?? 'Woman',
        interestedIn: List<String>.from(m['interestedIn'] ?? const ['Man']),
        area: m['area'] ?? 'C-Scheme',
        bio: m['bio'] ?? '',
        job: m['job'] ?? '',
        education: m['education'] ?? '',
        heightCm: m['heightCm'],
        lookingFor: m['lookingFor'] ?? 'Relationship',
        interests: List<String>.from(m['interests'] ?? const []),
        prompts: Map<String, String>.from(m['prompts'] ?? const {}),
        photos: List<String>.from(m['photos'] ?? const []),
        verified: m['verified'] ?? false,
        verificationStatus: m['verificationStatus'] ?? 'none',
        selfie: m['selfie'] ?? '',
        premium: m['premium'] ?? false,
        boostUntil: _dt(m['boostUntil']),
        blocked: List<String>.from(m['blocked'] ?? const []),
        lastActive: _dt(m['lastActive']),
      );
}

enum SwipeType { like, nope, superLike }

class MatchInfo {
  final String id;
  final UserProfile other;
  final String lastMessage;
  final DateTime? lastAt;
  final int unread;
  MatchInfo({
    required this.id,
    required this.other,
    this.lastMessage = '',
    this.lastAt,
    this.unread = 0,
  });
}

class ChatMessage {
  final String id;
  final String from;
  final String text;
  final String? imageUrl;
  final DateTime at;
  final bool read;
  ChatMessage({
    required this.id,
    required this.from,
    this.text = '',
    this.imageUrl,
    required this.at,
    this.read = false,
  });
}

class Filters {
  int minAge;
  int maxAge;
  double maxKm;
  bool verifiedOnly;
  Filters({
    this.minAge = 18,
    this.maxAge = 45,
    this.maxKm = 30,
    this.verifiedOnly = false,
  });
}
