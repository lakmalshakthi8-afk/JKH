# iOS Build with GitHub Actions (unsigned IPA)

This file explains how the repository builds an unsigned iOS IPA using GitHub Actions and how to sign/install it on a Mac using a free Apple ID.

What was added
- A GitHub Actions workflow: `.github/workflows/ios.yml` that builds an unsigned `.ipa` and uploads it as an artifact.

How to trigger
- Push to `main` or `master`, or use the Actions tab -> select `Build iOS` -> `Run workflow`.

Download artifacts
- After the workflow completes, download the `ios-artifacts` artifact from the workflow run. It contains `build/ios/ipa` and `build/ios/archive` directories.

Signing & Install on your iPhone (requires a Mac)
1. On a Mac, download the unsigned `.ipa` from the workflow artifacts.
2. Create a free Apple ID (if you don't have one). Note: free accounts can sign apps for personal development but cannot distribute on the App Store.
3. Open Xcode and connect your iPhone.
4. Create an in-place signing identity by opening the `ios/Runner.xcodeproj` in Xcode, then:
   - Select the `Runner` target -> Signing & Capabilities -> Team: choose your Apple ID (add via Xcode Preferences -> Accounts if necessary).
   - Change the Bundle Identifier (e.g. `com.yourname.tfclassification`) to a unique value.
5. To sign the downloaded IPA, use `ios-deploy` or `xcrun`/`altool`, or re-build locally with Xcode. A simple method:
   - Open the `Runner` project in Xcode and run the app directly on your device (this automatically signs and installs using your free account).

Notes and limitations
- Building and exporting a production-signed IPA that can be distributed requires an Apple Developer Program account.
- GitHub Actions builds on `macos-latest` and performs a no-codesign export. The unsigned IPA needs a signing step on a Mac.
- If you want automated signing in CI, you'll need to provide signing certificates and provisioning profiles (or use Fastlane match) and store credentials/secrets in GitHub Secrets. This requires a paid Apple Developer account.

If you want, I can:
- Add a Fastlane configuration to handle signing when you later provide Apple credentials.
- Add automatic bundle id substitution in the workflow if you prefer to keep the bundle id configurable via a repo secret.
