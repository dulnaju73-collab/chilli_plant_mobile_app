# Chilli Plant Health mobile app

Flutter client for chilli leaf disease scanning, scan history, and user profiles.

## Requirements

- Flutter stable with Dart 3
- Android SDK for Android development
- Firebase app configuration for authentication
- A running Chilli Plant Health API

## Run locally

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<api-host>:8000
```

For an Android emulator, the default API URL is `http://10.0.2.2:8000`. For a
physical phone, set `API_BASE_URL` to an address the phone can reach, such as
the development computer's LAN address. The value must not include `/api/v1`.

## Firebase setup

Flutter Firebase options are in `lib/core/config/firebase_options.dart`. The
Android Google Services Gradle plugin also expects the app's
`android/app/google-services.json`; download it from the Firebase console and
keep it local because that file is ignored by Git. Run `flutterfire configure`
when changing Firebase projects. Do not add Firebase Admin service-account
credentials or private keys to this mobile repository.

Enable Firebase Authentication methods used by the app in the Firebase
console. Protect Firebase data with Security Rules and App Check as appropriate.

## Launcher icon

The source artwork is in `assets/branding/`. To regenerate Android and iOS
launcher assets, install Python Pillow and `rsvg-convert` (from librsvg), then
run:

```sh
python3 tool/generate_app_icons.py
```
