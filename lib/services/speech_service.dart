import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService()
      : _stt = SpeechToText(),
        _tts = FlutterTts();

  final SpeechToText _stt;
  final FlutterTts _tts;
  bool _available = false;

  Future<bool> initialize({required void Function(bool) onListeningChanged}) async {
    _available = await _stt.initialize(
      onStatus: (status) => onListeningChanged(status == 'listening'),
      onError: (_) => onListeningChanged(false),
    );
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.47);
    await _tts.setPitch(0.95);
    return _available;
  }

  Future<void> startListening({required void Function(String) onResult}) async {
    if (!_available) return;
    await _stt.listen(
      localeId: 'en_IN',
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async => _stt.stop();

  Future<void> speak(String text, {required VoidCallback onStart, required VoidCallback onComplete}) async {
    _tts.setStartHandler(onStart);
    _tts.setCompletionHandler((_) => onComplete());
    _tts.setCancelHandler((_) => onComplete());
    _tts.setErrorHandler((_, __) => onComplete());
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    await _stt.cancel();
    await _tts.stop();
  }
}
