# Gulabi — dating app for Jaipur

Flutter (Android) app with a Firebase backend.

## How the APK is built
Every push to `main` runs `.github/workflows/build-apk.yml`, which builds a signed
release APK and publishes it under **Releases**.

Repository secrets used by the build:

| Secret | Purpose |
|---|---|
| `KEYSTORE_B64` | Fixed signing key (keeps the same SHA-1 so phone login keeps working and updates install over the old app) |
| `GOOGLE_SERVICES_JSON` | Full contents of Firebase `google-services.json`. Without it the app runs in **demo mode** (OTP `123456`, sample profiles). |
| `RAZORPAY_KEY` | Razorpay Key ID for Gold payments (optional) |

## Firebase setup
1. Android app package name: `com.jaipur.dating`
2. Add the signing SHA-1 and SHA-256 (shared separately) in Project settings → Your apps.
3. Enable Authentication → Phone, Firestore, Storage.
4. Publish `firebase/firestore.rules` and `firebase/storage.rules`.

## Admin tasks (Firebase console)
- Approve selfie verification: set `verified: true`, `verificationStatus: "approved"` on the user document.
- Review reports in the `reports` collection.
