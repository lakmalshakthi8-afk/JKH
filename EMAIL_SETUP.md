How to configure SMTP/email sending for VestaiGrade

This project supports sending emails directly from the app using SMTP (via the Dart `mailer` package). To keep credentials safe, the app uses `flutter_secure_storage` to store SMTP credentials on-device. Follow the steps below.

1) Recommended: Use an app-specific SMTP password
- For Gmail accounts with 2FA enabled, create an App Password and use it as the SMTP password.
- Using your main Gmail password is not recommended.

2) Configure SMTP settings in the app (on device)
- Open the app and go to the "Email List" screen.
- Tap the SMTP settings button (mail/settings icon) to open SMTP settings.
- Enter:
  - SMTP Username (your email address)
  - SMTP Password (app password or SMTP password)
  - SMTP Host (default: smtp.gmail.com)
  - SMTP Port (default: 587)
- Save settings. They are stored encrypted in the device secure storage.

3) Alternative: Provide credentials via `.env` during development (NOT for production)
- For local/dev testing, you may add `.env` at the project root with keys:
  - EMAIL=youremail@example.com
  - EMAILPASSWORD=yourpassword
  - SMTP_HOST=smtp.gmail.com
  - SMTP_PORT=587
- Do NOT commit `.env` to source control.

4) Security notes
- Never commit real SMTP credentials or API keys into the repository.
- Prefer server-side email sending for production (Cloud Function + SendGrid, etc.).
- Mobile SMTP is less reliable than server-sent email; consider moving sending to a backend for production-grade delivery.

5) Android-specific notes
- `flutter_secure_storage` uses the Android keystore and is supported on Android.
- Ensure your app's network policy allows TLS connections if using secure SMTP.

6) iOS-specific notes
- `flutter_secure_storage` uses Keychain on iOS.
- For Gmail, you may need app passwords.

If you want, I can:
- Add an in-app settings button if you don't see it in the UI.
- Implement a serverless Cloud Function to send emails server-side and update the app to call it.
