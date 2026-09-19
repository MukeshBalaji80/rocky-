# Rocky Companion

A production-oriented Flutter mobile app for Rocky, a voice-first AI companion. The first version prioritizes the core loop: **tap mic → speak → speech-to-text → AI response → persistent memory → TTS → animated orb**.

## Architecture

```text
UI
 ├── HomeScreen
 ├── RockyOrb
 └── SettingsScreen
       ↓
Core services
 ├── PersonalityEngine
 ├── SilenceEngine
 ├── SpeechService
 ├── AiClient
 └── NotificationService
       ↓
MemoryRepository (interface)
       ↓
SqliteMemoryRepository

Future:
Postgres/NeonMemoryRepository can replace SQLite without changing UI or AI orchestration.
```

## Important backend security decision

A mobile app should **not ship a permanent provider API secret** inside the APK. The included `AiClient` talks to an OpenAI-compatible `/chat/completions` endpoint, so the intended production setup is:

`Flutter app → your backend → model provider`

For local Android emulator development, the default endpoint is `http://10.0.2.2:3000/v1`.

## Create the native Flutter shell

This environment did not include the Flutter SDK, so the native Android/iOS shell cannot be compiled here. On a machine with Flutter installed:

```bash
flutter create .
flutter pub get
```

Then apply the platform permissions below and run the app.

## Android permissions

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

For local HTTP development only, add `android:usesCleartextTraffic="true"` to the `<application>` element. Use HTTPS in production.

## iOS permissions

In `ios/Runner/Info.plist`, add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Rocky uses the microphone for voice conversation.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Rocky converts your speech into text so it can respond.</string>
```

## Configure AI

Run with:

```bash
flutter run \
  --dart-define=ROCKY_API_BASE_URL=https://your-backend.example.com/v1 \
  --dart-define=ROCKY_MODEL=your-model-name
```

A key can be supplied for local testing with `ROCKY_API_KEY`, but do not embed a long-lived production key in a distributed app.

## Backend response contract

The included `backend/server.js` is a functional OpenAI-compatible proxy. Run it with Node 18+ after installing dependencies:

```bash
cd backend
npm install
OPENAI_API_KEY=your_server_secret npm start
```

Set `OPENAI_BASE_URL` if you use another OpenAI-compatible provider and `ROCKY_MODEL` for the deployed model. The backend must accept:

`POST /v1/chat/completions`

with an OpenAI-compatible JSON body containing `model`, `messages`, and `temperature`, and return:

```json
{
  "choices": [
    {"message": {"content": "Waiting, Mukesh."}}
  ]
}
```

## First-version behavior

- **Orb:** idle, listening, thinking, speaking, waiting, concerned states.
- **Listening:** expanding rings and radial waveform-like reactivity.
- **Thinking:** pulse and color-shift animation.
- **Speaking:** rhythmic movement while TTS is active.
- **Chat:** threaded local history persisted in SQLite.
- **Voice:** `speech_to_text` for input and `flutter_tts` for output.
- **Personality:** centralized prompt policy in `PersonalityEngine`.
- **Silence:** `SilenceEngine` tracks user activity and provides hooks for focus/busy gating.
- **Notifications:** local notification service is wired for proactive moments.
- **Settings:** voice replies, notifications, focus silence, personality intensity.

## Testing

Run:

```bash
flutter analyze
flutter test
flutter run
```

Manual acceptance flow:

1. Launch the app.
2. Grant microphone permission.
3. Tap the mic and speak naturally.
4. Confirm live transcription appears.
5. Stop speaking / tap stop.
6. Confirm the orb enters thinking state.
7. Confirm an AI response appears in the chat.
8. Confirm Rocky speaks the response aloud.
9. Relaunch the app and confirm the conversation remains.
10. Open Settings and verify voice/personality/focus controls.
11. Verify a focus/busy state suppresses proactive behavior before enabling notifications in production.

## Production hardening still required before store release

- Add authentication and rate limiting to the backend.
- Use HTTPS only.
- Add encrypted local storage if conversation content requires stronger at-rest protection.
- Add a real app lifecycle/context provider for focus, foreground/background, and optional calendar/activity signals.
- Replace the simple foreground proactive timer with a platform-aware background scheduler for store-grade proactive notifications.
- Add integration tests on real Android/iOS devices for microphone permissions, TTS, notification behavior, and network failures.
- Add a PostgreSQL/Neon implementation of `MemoryRepository` when cloud memory is needed.

## Milestone 1 validation notes

This source package is intentionally backend-safe: provider credentials belong on the backend, not in the distributed mobile app. The Flutter source can be generated into a native shell with `flutter create .`, then validated with `flutter analyze` and `flutter test` on a machine that has Flutter installed.

The backend also includes a dependency-free Node smoke test (`npm run smoke`) that checks the health route and the expected unconfigured-credentials behavior.
