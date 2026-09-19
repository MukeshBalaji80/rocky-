class SilenceEngine {
  DateTime? _lastUserActivity;
  bool _busy = false;

  void markUserActivity() => _lastUserActivity = DateTime.now();
  void setBusy(bool value) => _busy = value;

  bool shouldStaySilent({required bool focusMode}) {
    if (_busy) return true;
    if (focusMode) return true;
    final last = _lastUserActivity;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 20);
  }

  bool shouldProactivelyEngage({required bool focusMode, Duration idleThreshold = const Duration(minutes: 20)}) {
    if (focusMode || _busy) return false;
    final last = _lastUserActivity;
    if (last == null) return false;
    return DateTime.now().difference(last) >= idleThreshold;
  }
}
