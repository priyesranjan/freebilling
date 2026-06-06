import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  static const Map<String, Map<String, String>> _dict = {
    'new_sale': {
      'en': 'New Sale',
      'hi': 'नया बिल',
      'pa': 'ਨਵਾਂ ਬਿੱਲ',
      'bho': 'नया बिल',
      'mr': 'नवीन बिल',
    },
    'add_expense': {
      'en': 'Add Expense',
      'hi': 'खर्चा लिखें',
      'pa': 'ਖਰਚਾ ਲਿਖੋ',
      'bho': 'खरचा लिखीं',
      'mr': 'खर्च लिहा',
    },
    'customers': {
      'en': 'Customers',
      'hi': 'ग्राहक (खाता)',
      'pa': 'ਗਾਹਕ (ਖਾਤਾ)',
      'bho': 'ग्राहक (खाता)',
      'mr': 'ग्राहक (खाते)',
    },
    'reports': {
      'en': 'Reports',
      'hi': 'रिपोर्ट',
      'pa': 'ਰਿਪੋਰਟ',
      'bho': 'रिपोर्ट',
      'mr': 'अहवाल',
    },
    'money_in': {
      'en': 'Money In',
      'hi': 'पैसा आया',
      'pa': 'ਪੈਸੇ ਆਏ',
      'bho': 'पइसा आइल',
      'mr': 'पैसे आले',
    },
    'money_out': {
      'en': 'Money Out',
      'hi': 'पैसा गया',
      'pa': 'ਪੈਸੇ ਗਏ',
      'bho': 'पइसा गइल',
      'mr': 'पैसे गेले',
    },
    'home': {
      'en': 'Home',
      'hi': 'होम',
      'pa': 'ਹੋਮ',
      'bho': 'होम',
      'mr': 'होम',
    },
    'items': {
      'en': 'Items',
      'hi': 'सामान',
      'pa': 'ਸਮਾਨ',
      'bho': 'सामान',
      'mr': 'वस्तू',
    },
    'khata': {
      'en': 'Khata',
      'hi': 'खाता',
      'pa': 'ਖਾਤਾ',
      'bho': 'खाता',
      'mr': 'खाते',
    },
    'bills': {
      'en': 'Bills',
      'hi': 'बिल',
      'pa': 'ਬਿੱਲ',
      'bho': 'बिल',
      'mr': 'बिल',
    },
    'menu': {
      'en': 'Menu',
      'hi': 'मेनू',
      'pa': 'ਮੇਨੂ',
      'bho': 'मेनू',
      'mr': 'मेनू',
    },
  };

  static String tr(String key) {
    final lang = instance._currentLanguage;
    return _dict[key]?[lang] ?? _dict[key]?['en'] ?? key;
  }
}
