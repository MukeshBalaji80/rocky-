# Rocky Milestone 1 Verification Report

## Implemented

- Flutter core app structure with orb, chat, settings, voice services, notifications, personality, silence engine, and SQLite-backed memory.
- `MemoryRepository` abstraction keeps storage replaceable for a future PostgreSQL/Neon implementation.
- Backend proxy keeps provider credentials server-side and exposes an OpenAI-compatible `/v1/chat/completions` route.
- Fixed the HomeScreen settings initialization bug so the widget's `initialSettings` is used correctly.
- Added a dependency-free Node smoke test for `/health` and the expected unconfigured-credentials response.

## Validation completed in this environment

- Node.js syntax check passed for `backend/server.js`.
- Node.js syntax check passed for `backend/smoke_test.mjs`.
- Flutter/Dart validation was not run because the Flutter SDK and Dart SDK are not installed in this environment.
- Backend dependency installation could not be completed within the available execution window, so the live Express server smoke test was not claimed as passed.

## Required local validation

From the project root on a machine with Flutter installed:

```bash
flutter create .
flutter pub get
flutter analyze
flutter test
flutter run
```

For the backend:

```bash
cd backend
npm install
npm start
```

In a second terminal:

```bash
cd backend
npm run smoke
```

Do not treat the project as store-production-certified until microphone permissions, TTS, notifications, networking, and real-device behavior have been tested on Android/iOS.
