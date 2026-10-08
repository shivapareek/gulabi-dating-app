import 'package:firebase_core/firebase_core.dart';

/// Firebase settings are injected at build time (from google-services.json)
/// with --dart-define. When they are missing the app runs in demo mode.
class AppConfig {
  static const appName = 'Gulabi';
  static const _apiKey = String.fromEnvironment('FB_API_KEY');
  static const _appId = String.fromEnvironment('FB_APP_ID');
  static const _projectId = String.fromEnvironment('FB_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FB_SENDER_ID');
  static const _bucket = String.fromEnvironment('FB_STORAGE_BUCKET');
  static const razorpayKey = String.fromEnvironment('RAZORPAY_KEY');

  static bool get hasFirebase => _apiKey.isNotEmpty && _appId.isNotEmpty;

  static FirebaseOptions get firebaseOptions => const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        projectId: _projectId,
        messagingSenderId: _senderId,
        storageBucket: _bucket,
      );
}
