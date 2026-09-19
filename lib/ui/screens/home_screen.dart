import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/memory_repository.dart';
import '../../models/chat_message.dart';
import '../../models/rocky_settings.dart';
import '../../models/rocky_state.dart';
import '../../services/ai_client.dart';
import '../../services/personality_engine.dart';
import '../../services/silence_engine.dart';
import '../../services/notification_service.dart';
import '../../services/speech_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rocky_orb.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.aiClient, required this.speech, required this.notifications, required this.initialSettings});
  final MemoryRepository repository;
  final AiClient aiClient;
  final SpeechService speech;
  final NotificationService notifications;
  final RockySettings initialSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = const Uuid();
  final _personality = PersonalityEngine();
  final _silence = SilenceEngine();
  final List<ChatMessage> _messages = [];
  RockyState _state = RockyState.idle;
  late RockySettings _settings;
  Timer? _proactiveTimer;
  String _partialSpeech = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _loadHistory();
    _proactiveTimer = Timer.periodic(const Duration(minutes: 1), (_) => _maybeProactive());
    widget.speech.initialize(onListeningChanged: (listening) {
      if (!mounted) return;
      setState(() => _state = listening ? RockyState.listening : (_busy ? RockyState.thinking : RockyState.idle));
    });
  }

  Future<void> _loadHistory() async {
    final history = await widget.repository.getRecentMessages();
    if (!mounted) return;
    setState(() => _messages.addAll(history));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }


  Future<void> _maybeProactive() async {
    if (!mounted || !_settings.notificationsEnabled) return;
    final silent = _silence.shouldStaySilent(focusMode: _settings.silenceDuringFocus);
    if (silent || !_silence.shouldProactivelyEngage(focusMode: _settings.silenceDuringFocus)) return;
    await notifications.showCompanionMoment('You have been quiet for a while. Rocky is still here.');
    _silence.markUserActivity();
  }

  Future<void> _toggleMic() async {
    if (_state == RockyState.listening) {
      await widget.speech.stopListening();
      if (_partialSpeech.trim().isNotEmpty) {
        final text = _partialSpeech.trim();
        _partialSpeech = '';
        await _send(text);
      }
      return;
    }
    _silence.markUserActivity();
    setState(() {
      _state = RockyState.listening;
      _partialSpeech = '';
    });
    await widget.speech.startListening(onResult: (text) {
      if (!mounted) return;
      setState(() => _partialSpeech = text);
    });
  }

  Future<void> _send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _busy) return;
    _silence.markUserActivity();
    final user = ChatMessage(id: _uuid.v4(), role: MessageRole.user, text: clean, createdAt: DateTime.now());
    setState(() {
      _messages.add(user);
      _busy = true;
      _state = RockyState.thinking;
      _input.clear();
    });
    await widget.repository.saveMessage(user);
    _scrollToBottom();

    try {
      final history = await widget.repository.getRecentMessages(limit: 30);
      final reply = await widget.aiClient.generateReply(
        history: history,
        userText: clean,
        personalityPrompt: _personality.buildPrompt(intensity: _settings.personalityIntensity, recent: history),
      );
      final rocky = ChatMessage(id: _uuid.v4(), role: MessageRole.rocky, text: reply, createdAt: DateTime.now());
      await widget.repository.saveMessage(rocky);
      if (!mounted) return;
      setState(() {
        _messages.add(rocky);
        _busy = false;
        _state = _settings.voiceEnabled ? RockyState.speaking : RockyState.idle;
      });
      _scrollToBottom();
      if (_settings.voiceEnabled) {
        await widget.speech.speak(
          reply,
          onStart: () => mounted ? setState(() => _state = RockyState.speaking) : null,
          onComplete: () => mounted ? setState(() => _state = RockyState.waiting) : null,
        );
      } else {
        setState(() => _state = RockyState.waiting);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _state = RockyState.concerned;
      });
      final error = ChatMessage(id: _uuid.v4(), role: MessageRole.rocky, text: 'I cannot reach my voice today. Check the AI connection, question?', createdAt: DateTime.now());
      await widget.repository.saveMessage(error);
      setState(() => _messages.add(error));
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Rocky'), Text('your little digital presence', style: TextStyle(fontSize: 11, color: Colors.white54))]),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<RockySettings>(MaterialPageRoute(builder: (_) => SettingsScreen(settings: _settings)));
              if (result != null && mounted) setState(() => _settings = result);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(height: 260, child: RockyOrb(state: _state)),
            Text(_partialSpeech.isNotEmpty ? _partialSpeech : _stateLabel, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
            const SizedBox(height: 10),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text('Tap the mic. Rocky is waiting.', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(controller: _scroll, padding: const EdgeInsets.only(bottom: 12), itemCount: _messages.length, itemBuilder: (_, i) => MessageBubble(message: _messages[i])),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  String get _stateLabel => switch (_state) {
        RockyState.idle => 'quiet',
        RockyState.listening => 'listening',
        RockyState.thinking => 'thinking',
        RockyState.speaking => 'speaking',
        RockyState.waiting => 'waiting',
        RockyState.concerned => 'checking the connection',
      };

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Talk to Rocky…',
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _state == RockyState.listening ? Colors.redAccent : Colors.blueAccent),
              child: Icon(_state == RockyState.listening ? Icons.stop_rounded : Icons.mic_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _proactiveTimer?.cancel();
    widget.aiClient.dispose();
    widget.speech.dispose();
    super.dispose();
  }
}
