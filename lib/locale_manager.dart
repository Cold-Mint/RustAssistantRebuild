import 'package:flutter/material.dart';
import 'package:rust_assistant/global_depend.dart';

import 'constant.dart';

class LocaleManager extends ChangeNotifier {
  Locale _locale = Locale(Constant.defaultLanguage);

  Locale get locale => _locale;

  void loadLocale() {
    if (HiveHelper.containsKey(HiveHelper.language)) {
      var language = HiveHelper.get(
        HiveHelper.language,
        defaultValue: Constant.defaultLanguage,
      );
      _locale = Locale(language);
    } else {
      _locale = Locale(Constant.defaultLanguage);
    }
    notifyListeners();
  }
}
