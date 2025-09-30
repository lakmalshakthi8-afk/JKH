## iOS CI Troubleshooting Notes

If the GitHub Actions run fails on macOS, here are the most common causes and fixes:

- CocoaPods issues
  - Error: "[!] CocoaPods could not find compatible versions for pod" — run `pod repo update` or lock pod versions. The workflow already runs `pod repo update`.
  - Error installing CocoaPods — ensure Homebrew and Ruby are available on macOS runner; the workflow installs CocoaPods via Homebrew or Ruby gem.

- Flutter version mismatches
  - If plugins require a newer Flutter SDK, set `FLUTTER_CHANNEL` to `stable` or `beta` in the workflow. You can pin a Flutter version by installing from a specific channel or SDK URL.

- Code signing errors
  - Building for device or archive may request signing. We use `--no-codesign` so CI won't require Apple credentials. To install on a device you'll still need to sign the IPA locally.

- Missing Podfile or iOS platform settings
  - Flutter generates Podfile on `flutter build ios`. If a plugin requires platform >= 11.0 change `platform :ios, '11.0'` in `ios/Podfile` (if you add a Podfile manually).

- Bitcode or Swift version
  - If Xcode complains about Swift version, ensure `SWIFT_VERSION` in `project.pbxproj` is set (it's 5.0 in this project). For bitcode, Flutter sets `ENABLE_BITCODE = NO` in Release configuration already.

- Device provisioning
  - To run on a physical device from CI you need provisioning profiles and certificates. For local testing with a free Apple ID, open the project in Xcode and let Xcode manage signing.

If you post the CI logs I can analyze and propose a targeted fix.
