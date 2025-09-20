import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rust_assistant/color_picker_dialog.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:rust_assistant/locale_manager.dart';
import 'package:rust_assistant/theme_provider.dart';

import '../code_data_base.dart';

class LanguageAndAppearancePage extends StatefulWidget {
  final bool embeddedPattern;
  final Function(bool)? onCompleted;

  const LanguageAndAppearancePage({
    super.key,
    required this.embeddedPattern,
    this.onCompleted,
  });

  @override
  State<LanguageAndAppearancePage> createState() =>
      _LanguageAndAppearancePageState();
}

class _LanguageAndAppearancePageState extends State<LanguageAndAppearancePage> {
  bool _useDynamicColor = true;
  Color _selectedColor = Colors.blue;
  int _themeModeValue = 0;
  bool _show = false;
  LocaleManager? _localeManager;
  Map<String, String> languageMap = {"en": "English", "zh": "简体中文"};

  @override
  void initState() {
    super.initState();
    _localeManager = Provider.of<LocaleManager>(context, listen: false);
    _loadFromHive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCompleted?.call(true);
    });
    if (widget.embeddedPattern || _show) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (HiveHelper.containsKey(HiveHelper.language)) {
        _localeManager?.loadLocale();
      } else {
        String systemLocale = WidgetsBinding.instance.platformDispatcher.locale
            .toLanguageTag();
        var index = systemLocale.lastIndexOf("-");
        if (index > -1) {
          systemLocale = systemLocale.substring(0, index);
        }
        String languageCode = Localizations.localeOf(context).languageCode;
        if (systemLocale != languageCode) {
          if (languageMap.containsKey(systemLocale)) {
            _show = true;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: Text('Change app language'),
                  content: Text(
                    'Switch app language to "${languageMap[systemLocale] ?? systemLocale}"?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // 先关闭对话框
                        _applyLanguage(languageCode); // 应用语言
                      }, // 取消
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // 先关闭对话框
                        _applyLanguage(systemLocale); // 应用语言
                      },
                      child: Text('Apply'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    });
  }

  void _loadFromHive() {
    if (HiveHelper.containsKey(HiveHelper.dynamicColorEnabled)) {
      _useDynamicColor = HiveHelper.get(
        HiveHelper.dynamicColorEnabled,
        defaultValue: true,
      );
    }

    if (HiveHelper.containsKey(HiveHelper.seedColor)) {
      var seed = HiveHelper.get(HiveHelper.seedColor);
      _selectedColor = Color(seed);
    }

    if (HiveHelper.containsKey(HiveHelper.darkMode)) {
      _themeModeValue = HiveHelper.get(HiveHelper.darkMode, defaultValue: 0);
    }
  }

  void _applyLanguage(String language) async {
    HiveHelper.put(HiveHelper.language, language);
    //语言改变后应该加载代码信息。
    await CodeDataBase.loadCodeInfo(language);
    await CodeDataBase.loadLanguageCode(language);
    await CodeDataBase.loadSectionInfo(language);
    await CodeDataBase.loadUnitsTemplate(language);
    await CodeDataBase.loadLogicalBooleanTranslate(language);
    await CodeDataBase.loadEnumData(language);
    await CodeDataBase.loadUnits(language);
    await CodeDataBase.generateCodeIntoMemory();
    if (_localeManager != null) {
      _localeManager?.loadLocale();
    }
  }

  List<Widget> _getCoreWidget() {
    return [
      ListTile(
        title: Text(AppLocalizations.of(context)!.language),
        subtitle: Text(AppLocalizations.of(context)!.translator),
        trailing: DropdownButton<Locale>(
          value: _localeManager!.locale,
          items: AppLocalizations.supportedLocales.map((locale) {
            return DropdownMenuItem<Locale>(
              value: locale,
              child: Text(
                languageMap[locale.languageCode] ?? locale.languageCode,
              ),
            );
          }).toList(),
          onChanged: (locale) async {
            _applyLanguage(locale!.languageCode);
          },
        ),
      ),
      SwitchListTile(
        title: Text(AppLocalizations.of(context)!.dynamicColor),
        value: _useDynamicColor,
        onChanged: (value) {
          setState(() {
            _useDynamicColor = value;
          });
          HiveHelper.put(HiveHelper.dynamicColorEnabled, value);
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          themeProvider.updateTheme(context);
        },
      ),
      if (!_useDynamicColor)
        ListTile(
          title: Text(AppLocalizations.of(context)!.themeColor),
          trailing: CircleAvatar(backgroundColor: _selectedColor, radius: 15),
          onTap: () {
            _pickColor(context);
          },
        ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.darkTheme),
        trailing: DropdownButton<int>(
          value: _themeModeValue,
          items: [
            DropdownMenuItem(
              value: Constant.darkModeFollowSystem,
              child: Text(AppLocalizations.of(context)!.followSystem),
            ),
            DropdownMenuItem(
              value: Constant.darkModeFollowLight,
              child: Text(AppLocalizations.of(context)!.lightTheme),
            ),
            DropdownMenuItem(
              value: Constant.darkModeFollowDark,
              child: Text(AppLocalizations.of(context)!.darkColor),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _themeModeValue = value;
            });
            HiveHelper.put(HiveHelper.darkMode, value);
            Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).updateTheme(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedPattern) {
      return Column(children: _getCoreWidget());
    }
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: _getCoreWidget(),
      ),
    );
  }

  void _pickColor(BuildContext context) async {
    Color? picked = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: _selectedColor),
    );
    if (picked == null) {
      return;
    }
    if (context.mounted) {
      setState(() {
        _selectedColor = picked;
      });
      HiveHelper.put(HiveHelper.seedColor, picked.toARGB32());
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.updateTheme(context);
    }
  }
}
