import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sqlite_memory_repository.dart';
import 'services/ai_client.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'models/rocky_settings.dart';
import 'ui/screens/home_screen.dart';
import 'utils/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = SqliteMemoryRepository();
  await repository.initialize();

  final notifications = NotificationService();
  await notifications.initialize();

  final speech = SpeechService();
  final aiClient = AiClient(
    baseUrl: RockyEnv.apiBaseUrl,
    apiKey: RockyEnv.apiKey,
    model: RockyEnv.model,
  );

  final prefs = await SharedPreferences.getInstance();
  final settings = RockySettings(
    voiceEnabled: prefs.getBool('voiceEnabled') ?? true,
    notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
    personalityIntensity: prefs.getDouble('personalityIntensity') ?? 0.75,
    silenceDuringFocus: prefs.getBool('silenceDuringFocus') ?? true,
  );

  runApp(RockyApp(repository: repository, aiClient: aiClient, speech: speech, notifications: notifications, initialSettings: settings));
}

class RockyApp extends StatelessWidget {
  const RockyApp({super.key, required this.repository, required this.aiClient, required this.speech, required this.notifications, required this.initialSettings});
  final SqliteMemoryRepository repository;
  final AiClient aiClient;
  final SpeechService speech;
  final NotificationService notifications;
  final RockySettings initialSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rocky',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A12),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark),
      ),
      home: HomeScreen(repository: repository, aiClient: aiClient, speech: speech, notifications: notifications, initialSettings: initialSettings),
    );
  }
}
