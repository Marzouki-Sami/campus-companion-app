/// Build-time configuration, passed with `--dart-define-from-file=env.json`
/// (see `env.example.json`). Nothing here is a secret: the publishable key is meant
/// to ship inside the app, and access is enforced by Row Level Security.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
