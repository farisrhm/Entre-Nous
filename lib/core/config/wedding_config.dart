abstract final class WeddingConfig {
  static final wedding = DateTime.parse('2027-01-23T13:00:00Z');
  static final dayEnd = DateTime.parse('2027-01-23T23:00:00Z');
  static final calendarStart = DateTime.parse('2026-12-24T23:00:00Z');

  static const appId = String.fromEnvironment('PARSE_APP_ID');
  static const clientKey = String.fromEnvironment('PARSE_CLIENT_KEY');
  static const server = String.fromEnvironment(
    'PARSE_SERVER_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const cloudMode = String.fromEnvironment(
    'WEDDING_CLOUD_MODE',
    defaultValue: 'auto',
  );

  static String get _mode => cloudMode.toLowerCase().trim();
  static bool get cloudRequested => _mode != 'off';
  static bool get supabaseEnabled =>
      (_mode == 'auto' || _mode == 'supabase' || _mode == 'on') &&
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty;
  static bool get parseEnabled =>
      (_mode == 'parse' || _mode == 'on') &&
      appId.isNotEmpty &&
      clientKey.isNotEmpty;
  static bool get cloudEnabled => supabaseEnabled || parseEnabled;
}
