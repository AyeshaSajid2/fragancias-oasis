//Class for language conversion of users screens

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'menu': 'Menu',
      'links': 'Links',
      'home': 'Home',
      'notifications': 'Notifications',
      'login': 'Login',
      'videos': 'Videos',
      'contactUs': 'Contact Us',
      'socialLinks': 'Social Links',
    },
    'es': {
      'menu': 'Menú',
      'links': 'Enlaces',
      'home': 'Inicio',
      'notifications': 'Notificaciones',
      'login': 'Iniciar sesión',
      'videos': 'Videos',
      'contactUs': 'Contáctenos',
      'socialLinks': 'Enlaces sociales',
    },
  };

  // Method to get the translated value
  String get(String key, {String languageCode = 'en'}) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}
