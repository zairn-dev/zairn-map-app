class AppConfig {
  const AppConfig._();

  // Override in local/dev builds with:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gggdmmgrorbxcepdlgtm.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_er1BELHp1AZnQtS2tQBajg_NWHU9VGg',
  );
}
