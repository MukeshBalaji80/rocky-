import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/rocky_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});
  final RockySettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late RockySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voiceEnabled', _settings.voiceEnabled);
    await prefs.setBool('notificationsEnabled', _settings.notificationsEnabled);
    await prefs.setBool('silenceDuringFocus', _settings.silenceDuringFocus);
    await prefs.setDouble('personalityIntensity', _settings.personalityIntensity);
    if (mounted) Navigator.pop(context, _settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rocky settings')),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('Voice replies'), subtitle: const Text('Rocky speaks responses aloud'), value: _settings.voiceEnabled, onChanged: (v) => setState(() => _settings = _settings.copyWith(voiceEnabled: v))),
          SwitchListTile(title: const Text('Notifications'), subtitle: const Text('Allow proactive companion moments'), value: _settings.notificationsEnabled, onChanged: (v) => setState(() => _settings = _settings.copyWith(notificationsEnabled: v))),
          SwitchListTile(title: const Text('Silence during focus'), subtitle: const Text('Do not proactively interrupt focus periods'), value: _settings.silenceDuringFocus, onChanged: (v) => setState(() => _settings = _settings.copyWith(silenceDuringFocus: v))),
          const ListTile(title: Text('Personality intensity')),
          Slider(value: _settings.personalityIntensity, onChanged: (v) => setState(() => _settings = _settings.copyWith(personalityIntensity: v)), min: 0, max: 1, divisions: 10),
          Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('Save'))),
        ],
      ),
    );
  }
}
