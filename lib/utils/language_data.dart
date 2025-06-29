class LanguageOption {
  final String code;
  final String name;

  LanguageOption({required this.code, required this.name});
}

final List<LanguageOption> languageOptions = [
  LanguageOption(code: 'pt', name: 'Português'),
  LanguageOption(code: 'es', name: 'Español'),
  LanguageOption(code: 'en', name: 'English'),
];
