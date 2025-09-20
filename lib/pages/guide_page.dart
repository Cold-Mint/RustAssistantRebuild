import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/pages/language_and_appearance.dart';
import 'package:rust_assistant/pages/path_config_page.dart';
import 'package:rust_assistant/pages/permission_manager_page.dart';

import '../l10n/app_localizations.dart';
import 'home_page.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GuidePageState();
  }
}

class _GuidePageState extends State<GuidePage> {
  final List<_Step> _steps = [];
  int _step = 0;
  final List<bool> _isCompleted = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _steps.clear();
    _isCompleted.clear();
    _addSteps(
      (index) => _Step(
        AppLocalizations.of(context)!.languageAndAppearance,
        () => LanguageAndAppearancePage(
          embeddedPattern: false,
          onCompleted: (b) => {
            setState(() {
              _isCompleted[index] = b;
            }),
          },
        ),
      ),
    );
    if (Platform.isAndroid) {
      _addSteps(
        (index) => _Step(
          AppLocalizations.of(context)!.permission,
          () => PermissionManagerPage(
            embeddedPattern: false,
            onCompleted: (b) => {
              setState(() {
                _isCompleted[index] = b;
              }),
            },
          ),
        ),
      );
    }
    _addSteps(
      (index) => _Step(
        AppLocalizations.of(context)!.pathConfig,
        () => PathConfigPage(
          modPathConfigLegal: (b) => {
            setState(() {
              _isCompleted[index] = b;
            }),
          },
        ),
      ),
    );
  }

  void _addSteps(_Step Function(int) stepFunc) {
    var index = _steps.length;
    _isCompleted.add(false);
    _steps.add(stepFunc.call(index));
  }

  String getTitle() {
    if (_step >= _steps.length) {
      return "";
    }
    return _steps[_step].title ?? "";
  }

  Widget getContent() {
    return _steps[_step].widget?.call() ??
        Center(child: Text(AppLocalizations.of(context)!.noContent));
  }

  @override
  Widget build(BuildContext context) {
    var nextIndex = _step + 1;
    return Scaffold(
      appBar: AppBar(title: Text(getTitle())),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: getContent()),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text("$nextIndex/${_steps.length}"),
                  Expanded(child: SizedBox()),
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => {
                        setState(() {
                          if (_step > 0) {
                            _step--;
                          }
                        }),
                      },
                      child: Text(AppLocalizations.of(context)!.previous),
                    ),
                  SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isCompleted[_step]
                        ? () {
                            if (nextIndex >= _steps.length) {
                              HiveHelper.put(HiveHelper.runedGuide, true);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ),
                              );
                            } else {
                              setState(() {
                                _step++;
                              });
                            }
                          }
                        : null,
                    child: Text(
                      nextIndex >= _steps.length
                          ? AppLocalizations.of(context)!.finish
                          : AppLocalizations.of(context)!.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String? title;
  final Widget Function()? widget;

  _Step(this.title, this.widget);
}
