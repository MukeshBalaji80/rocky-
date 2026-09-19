class RockySettings {
  const RockySettings({
    this.voiceEnabled = true,
    this.notificationsEnabled = true,
    this.personalityIntensity = 0.75,
    this.silenceDuringFocus = true,
  });

  final bool voiceEnabled;
  final bool notificationsEnabled;
  final double personalityIntensity;
  final bool silenceDuringFocus;

  RockySettings copyWith({
    bool? voiceEnabled,
    bool? notificationsEnabled,
    double? personalityIntensity,
    bool? silenceDuringFocus,
  }) {
    return RockySettings(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      personalityIntensity: personalityIntensity ?? this.personalityIntensity,
      silenceDuringFocus: silenceDuringFocus ?? this.silenceDuringFocus,
    );
  }
}
