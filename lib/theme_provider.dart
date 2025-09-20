import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';

import 'global_depend.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _dynamicColorEnabled = true;
  Color _seedColor = Colors.blue;

  ThemeMode get themeMode => _themeMode;

  bool get dynamicColorEnabled => _dynamicColorEnabled;

  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    _themeMode = _getThemeModeFromHive();
    if (HiveHelper.containsKey(HiveHelper.dynamicColorEnabled)) {
      _dynamicColorEnabled = HiveHelper.get(HiveHelper.dynamicColorEnabled);
    }
    if (HiveHelper.containsKey(HiveHelper.seedColor)) {
      _seedColor = Color(HiveHelper.get(HiveHelper.seedColor));
    }
    notifyListeners();
  }

  ThemeMode _getThemeModeFromHive() {
    final int themeModeIndex = HiveHelper.get(HiveHelper.darkMode);
    switch (themeModeIndex) {
      case Constant.darkModeFollowLight:
        return ThemeMode.light;
      case Constant.darkModeFollowDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void updateTheme(BuildContext context) {
    _loadThemeSettings();
    Future.delayed(Duration(milliseconds: 300), () {
      if (context.mounted) {
        setSystemUIOverlayStyle(context);
      }
    });
  }

  void setSystemUIOverlayStyle(BuildContext context) {
    final themeMode = _getThemeModeFromHive();
    bool isDarkMode = false;
    if (themeMode == ThemeMode.dark) {
      isDarkMode = true;
    } else if (themeMode == ThemeMode.light) {
      isDarkMode = false;
    } else {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
    }
    final systemNavBarColor = Theme.of(context).scaffoldBackgroundColor;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: systemNavBarColor,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
