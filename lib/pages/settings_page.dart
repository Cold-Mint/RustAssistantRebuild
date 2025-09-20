import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/databeans/game_version.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/pages/language_and_appearance.dart';
import 'package:rust_assistant/pages/path_config_page.dart';
import 'package:rust_assistant/pages/permission_manager_page.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingsStatus();
  }
}

class _SettingsStatus extends State<SettingsPage> {
  bool _automaticIndexConstruction = !Platform.isAndroid;
  bool _autoSave = true;
  bool _deleteOriginalFile = true;
  List<GameVersion>? _gameVersionList;
  late int _selectedGameVersion;
  late int _archivedFileLoadingLimit;
  String? versionName;
  String? versionNumber;
  int _openWorkspaceAfterCreateMod = Constant.openWorkSpaceAsk;

  @override
  void initState() {
    super.initState();
    if (HiveHelper.containsKey(HiveHelper.automaticIndexConstruction)) {
      _automaticIndexConstruction = HiveHelper.get(
        HiveHelper.automaticIndexConstruction,
        defaultValue: !Platform.isAndroid,
      );
    }
    if (HiveHelper.containsKey(HiveHelper.autoSave)) {
      _autoSave = HiveHelper.get(HiveHelper.autoSave, defaultValue: true);
    }

    if (HiveHelper.containsKey(
      HiveHelper.deleteOriginalFileAfterDecompression,
    )) {
      _deleteOriginalFile = HiveHelper.get(
        HiveHelper.deleteOriginalFileAfterDecompression,
        defaultValue: true,
      );
    }

    if (HiveHelper.containsKey(HiveHelper.openWorkspaceAfterCreateMod)) {
      _openWorkspaceAfterCreateMod = HiveHelper.get(
        HiveHelper.openWorkspaceAfterCreateMod,
        defaultValue: Constant.openWorkSpaceAsk,
      );
    }
    _gameVersionList = CodeDataBase.getGameVersion()
        .where((gv) => gv.visible == true)
        .toList();
    if (HiveHelper.containsKey(HiveHelper.targetGameVersion)) {
      _selectedGameVersion = HiveHelper.get(HiveHelper.targetGameVersion);
    } else {
      if (_gameVersionList!.isNotEmpty) {
        _selectedGameVersion = _gameVersionList!.last.versionCode!;
      }
    }
    if (HiveHelper.containsKey(HiveHelper.archivedFileLoadingLimit)) {
      _archivedFileLoadingLimit = HiveHelper.get(
        HiveHelper.archivedFileLoadingLimit,
      );
    } else {
      _archivedFileLoadingLimit = Constant.defaultArchivedFileLoadingLimit;
    }
    _loadVersionInfo();
  }

  void _loadVersionInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      versionName = packageInfo.version;
      versionNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.languageAndAppearance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LanguageAndAppearancePage(embeddedPattern: true),
          Divider(),
          if (Platform.isAndroid)
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    AppLocalizations.of(context)!.permission,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          if (Platform.isAndroid) SizedBox(height: 8),
          if (Platform.isAndroid) PermissionManagerPage(embeddedPattern: true),
          if (Platform.isAndroid) Divider(),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.pathConfig,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          PathConfigPage(),
          Divider(),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.editor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.automaticIndexConstruction,
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.automaticIndexConstructionTip,
            ),
            value: _automaticIndexConstruction,
            onChanged: (value) {
              setState(() {
                _automaticIndexConstruction = value;
              });
              HiveHelper.put(HiveHelper.automaticIndexConstruction, value);
            },
          ),
          SizedBox(height: 8),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.autoSave),
            subtitle: Text(AppLocalizations.of(context)!.autoSaveTip),
            value: _autoSave,
            onChanged: (value) {
              setState(() {
                _autoSave = value;
              });
              HiveHelper.put(HiveHelper.autoSave, value);
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.targetGameVersion),
            subtitle: Text(
              AppLocalizations.of(context)!.targetGameVersionMessage,
            ),
            trailing: DropdownButton<int>(
              value: _selectedGameVersion,
              items: _gameVersionList?.map((gameVersion) {
                return DropdownMenuItem<int>(
                  value: gameVersion.versionCode ?? 0,
                  child: Text(gameVersion.versionName ?? ""),
                );
              }).toList(),
              onChanged: (gameVersion) async {
                if (gameVersion == null) {
                  return;
                }
                HiveHelper.put(HiveHelper.targetGameVersion, gameVersion);
                await CodeDataBase.setTargetVersion(
                  HiveHelper.get(HiveHelper.language),
                  gameVersion,
                );
                setState(() {
                  _selectedGameVersion = gameVersion;
                });
              },
            ),
          ),
          Divider(),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  AppLocalizations.of(context)!.mods,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.readInfoArchiveFile),
            subtitle: Text(
              AppLocalizations.of(context)!.readInfoArchiveFileSub,
            ),
            trailing: DropdownButton<int>(
              value: _archivedFileLoadingLimit,
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile0Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 1048576,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile1Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 3145728,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile3Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 5242880,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile5Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 10485760,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile10Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 31457280,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile30Mb,
                  ),
                ),
                DropdownMenuItem(
                  value: 52428800,
                  child: Text(
                    AppLocalizations.of(context)!.readInfoArchiveFile50Mb,
                  ),
                ),
              ],
              onChanged: (archivedFileLoadingLimit) async {
                if (archivedFileLoadingLimit == null) {
                  return;
                }
                HiveHelper.put(
                  HiveHelper.archivedFileLoadingLimit,
                  archivedFileLoadingLimit,
                );
                setState(() {
                  _archivedFileLoadingLimit = archivedFileLoadingLimit;
                });
              },
            ),
          ),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.openWorkspaceAfterCreatingTheFile,
            ),
            trailing: DropdownButton<int>(
              value: _openWorkspaceAfterCreateMod,
              items: [
                DropdownMenuItem(
                  value: Constant.openWorkSpaceAsk,
                  child: Text(AppLocalizations.of(context)!.openWorkSpaceAsk),
                ),
                DropdownMenuItem(
                  value: Constant.openWorkSpaceAlways,
                  child: Text(
                    AppLocalizations.of(context)!.openWorkSpaceAlways,
                  ),
                ),
                DropdownMenuItem(
                  value: Constant.openWorkSpaceNever,
                  child: Text(AppLocalizations.of(context)!.openWorkSpaceNever),
                ),
              ],
              onChanged: (openWorkspaceAfterCreateMod) async {
                if (openWorkspaceAfterCreateMod == null) {
                  return;
                }
                HiveHelper.put(
                  HiveHelper.openWorkspaceAfterCreateMod,
                  openWorkspaceAfterCreateMod,
                );
                setState(() {
                  _openWorkspaceAfterCreateMod = openWorkspaceAfterCreateMod;
                });
              },
            ),
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.deleteOriginalFile),
            value: _deleteOriginalFile,
            onChanged: (value) {
              setState(() {
                _deleteOriginalFile = value;
              });
              HiveHelper.put(
                HiveHelper.deleteOriginalFileAfterDecompression,
                value,
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.github),
            subtitle: Text(AppLocalizations.of(context)!.githubSub),
            trailing: TextButton(
              onPressed: () async {
                final uri = Uri.parse(
                  "https://github.com/Cold-Mint/RustAssistantRebuild",
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.fail),
                      ),
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.view),
            ),
          ),
        ],
      ),
    );
  }
}
