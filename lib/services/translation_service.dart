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
      'gu': 'નવું બિલ',
      'bn': 'নতুন বিল',
      'ta': 'புதிய பில்',
      'te': 'కొత్త బిల్లు',
      'kn': 'ಹೊಸ ಬಿಲ್',
    },
    'add_expense': {
      'en': 'Add Expense',
      'hi': 'खर्चा लिखें',
      'pa': 'ਖਰਚਾ ਲਿਖੋ',
      'bho': 'खरचा लिखीं',
      'mr': 'खर्च लिहा',
      'gu': 'ખર્ચ ઉમેરો',
      'bn': 'খরচ যোগ করুন',
      'ta': 'செலவைச் சேர்க்கவும்',
      'te': 'ఖర్చు జోడించండి',
      'kn': 'ಖರ್ಚು ಸೇರಿಸಿ',
    },
    'customers': {
      'en': 'Customers',
      'hi': 'ग्राहक (खाता)',
      'pa': 'ਗਾਹਕ (ਖਾਤਾ)',
      'bho': 'ग्राहक (खाता)',
      'mr': 'ग्राहक (खाते)',
      'gu': 'ગ્રાહકો',
      'bn': 'গ্রাহক',
      'ta': 'வாடிக்கையாளர்கள்',
      'te': 'వినియోగదారులు',
      'kn': 'ಗ್ರಾಹಕರು',
    },
    'reports': {
      'en': 'Reports',
      'hi': 'रिपोर्ट',
      'pa': 'ਰਿਪੋਰਟ',
      'bho': 'रिपोर्ट',
      'mr': 'अहवाल',
      'gu': 'રિપોર્ટ',
      'bn': 'রিপোর্ট',
      'ta': 'அறிக்கைகள்',
      'te': 'రిపోర్ట్',
      'kn': 'ವರದಿ',
    },
    'money_in': {
      'en': 'Money In',
      'hi': 'पैसा आया',
      'pa': 'ਪੈਸੇ ਆਏ',
      'bho': 'पइसा आइल',
      'mr': 'पैसे आले',
      'gu': 'પૈસા આવ્યા',
      'bn': 'টাকা এসেছে',
      'ta': 'பணம் வந்தது',
      'te': 'డబ్బు వచ్చింది',
      'kn': 'ಹಣ ಬಂದಿದೆ',
    },
    'money_out': {
      'en': 'Money Out',
      'hi': 'पैसा गया',
      'pa': 'ਪੈਸੇ ਗਏ',
      'bho': 'पइसा गइल',
      'mr': 'पैसे गेले',
      'gu': 'પૈસા ગયા',
      'bn': 'টাকা গেছে',
      'ta': 'பணம் சென்றது',
      'te': 'డబ్బు పోయింది',
      'kn': 'ಹಣ ಹೋಗಿದೆ',
    },
    'home': {
      'en': 'Home',
      'hi': 'होम',
      'pa': 'ਹੋਮ',
      'bho': 'होम',
      'mr': 'होम',
      'gu': 'હોમ',
      'bn': 'হোম',
      'ta': 'முகப்பு',
      'te': 'హోమ్',
      'kn': 'ಹೋಮ್',
    },
    'items': {
      'en': 'Items',
      'hi': 'सामान',
      'pa': 'ਸਮਾਨ',
      'bho': 'सामान',
      'mr': 'वस्तू',
      'gu': 'વસ્તુઓ',
      'bn': 'জিনিসপত্র',
      'ta': 'பொருட்கள்',
      'te': 'వస్తువులు',
      'kn': 'ವಸ್ತುಗಳು',
    },
    'khata': {
      'en': 'Khata',
      'hi': 'खाता',
      'pa': 'ਖਾਤਾ',
      'bho': 'खाता',
      'mr': 'खाते',
      'gu': 'ખાતું',
      'bn': 'খাতা',
      'ta': 'கணக்கு',
      'te': 'ఖాతా',
      'kn': 'ಖಾತೆ',
    },
    'bills': {
      'en': 'Bills',
      'hi': 'बिल',
      'pa': 'ਬਿੱਲ',
      'bho': 'बिल',
      'mr': 'बिल',
      'gu': 'બિલ',
      'bn': 'বিল',
      'ta': 'பில்கள்',
      'te': 'బిల్లులు',
      'kn': 'ಬಿಲ್ಲುಗಳು',
    },
    'menu': {
      'en': 'Menu',
      'hi': 'मेनू',
      'pa': 'ਮੇਨੂ',
      'bho': 'मेनू',
      'mr': 'मेनू',
      'gu': 'મેનુ',
      'bn': 'মেনু',
      'ta': 'மெனு',
      'te': 'మెనూ',
      'kn': 'ಮೆನು',
    },
  };

  static String tr(String key) {
    final lang = instance._currentLanguage;
    return _dict[key]?[lang] ?? _dict[key]?['en'] ?? key;
  }
}
