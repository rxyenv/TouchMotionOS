/// Languages the launcher UI (and voice guide) supports. Shared by the
/// standalone language screen and the settings page picker.
class AppLanguage {
  const AppLanguage(this.code, this.name, this.native);

  final String code;
  final String name;
  final String native;
}

const appLanguages = <AppLanguage>[
  AppLanguage('en', 'English', 'English'),
  AppLanguage('hi', 'Hindi', 'हिन्दी'),
  AppLanguage('te', 'Telugu', 'తెలుగు'),
  AppLanguage('ta', 'Tamil', 'தமிழ்'),
  AppLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  AppLanguage('ml', 'Malayalam', 'മലയാളം'),
];
