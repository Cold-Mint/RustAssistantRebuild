import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rust_assistant/pages/splash_page.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:rust_assistant/theme_provider.dart';

import 'global_depend.dart';
import 'l10n/app_localizations.dart';
import 'locale_manager.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveHelper();
  runApp(const MyApp());
}

Future initHiveHelper() async {
  var userData = await GlobalDepend.getUserDataFolder();
  if (userData == null) {
    return;
  }
  var userDataDir = Directory(userData);
  if (!await userDataDir.exists()) {
    userDataDir.create();
  }
  await HiveHelper.init(userData);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleManager()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleManager, ThemeProvider>(
        builder: (context, localeManager, themeProvider, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              ColorScheme lightColorScheme;
              ColorScheme darkColorScheme;
              if (themeProvider.dynamicColorEnabled &&
                  lightDynamic != null &&
                  darkDynamic != null) {
                lightColorScheme = ColorScheme.fromSeed(
                  seedColor: lightDynamic.primary,
                  brightness: Brightness.light,
                );
                darkColorScheme = ColorScheme.fromSeed(
                  seedColor: darkDynamic.primary,
                  brightness: Brightness.dark,
                );
              } else {
                lightColorScheme = ColorScheme.fromSeed(
                  seedColor: themeProvider.seedColor,
                  brightness: Brightness.light,
                );
                darkColorScheme = ColorScheme.fromSeed(
                  seedColor: themeProvider.seedColor,
                  brightness: Brightness.dark,
                );
              }

              return MaterialApp(
                navigatorObservers: [routeObserver],
                title:
                    AppLocalizations.of(context)?.appName ?? "铁锈助手Rebuild",
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                  fontFamily: 'Noto',
                ),
                darkTheme: ThemeData(
                  colorScheme: darkColorScheme,
                  useMaterial3: true,
                  fontFamily: 'Noto',
                ),
                supportedLocales: AppLocalizations.supportedLocales,
                locale: localeManager.locale,
                themeMode: themeProvider.themeMode,
                home: SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
