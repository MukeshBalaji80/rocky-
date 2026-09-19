class RockyEnv {
  static const apiBaseUrl = String.fromEnvironment(
    'ROCKY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/v1',
  );
  static const apiKey = String.fromEnvironment('ROCKY_API_KEY', defaultValue: '');
  static const model = String.fromEnvironment('ROCKY_MODEL', defaultValue: 'rocky');
}
