Firebase setup (Android + iOS)

This repo currently does not contain Firebase configuration files. To enable Firebase for both platforms:

1. In the Firebase Console, add an iOS app and download `GoogleService-Info.plist`. Place it at `ios/Runner/GoogleService-Info.plist`.
2. Add an Android app in Firebase and download `google-services.json`. Place it at `android/app/google-services.json`.
3. The project includes the `firebase_core` dependency and `Firebase.initializeApp()` is called in `lib/main.dart`.
4. Commit the two config files (if you want them in the repo) or store them securely and add during CI using repository secrets or via `actions/upload-artifact` when needed.

After adding the platform config files, re-run the GitHub Actions workflow to produce an iOS archive/IPA that includes Firebase initialization.
