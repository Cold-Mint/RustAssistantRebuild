import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/global_depend.dart';

import '../l10n/app_localizations.dart';

class PathConfigPage extends StatefulWidget {
  final Function(bool)? modPathConfigLegal;

  const PathConfigPage({super.key, this.modPathConfigLegal});

  @override
  State<StatefulWidget> createState() {
    return _PathConfigPageState();
  }
}

class _PathConfigPageState extends State<PathConfigPage> {
  bool _enableSteamMod = false;
  final TextEditingController _modEditingController = TextEditingController();
  final TextEditingController _steamModEditingController =
      TextEditingController();
  String? _steamModEditingErrorText;
  String? _modEditingErrorText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!_loadHiveValue()) {
      setDefaultPath(false);
    }
    //不要动 HiveHelper.put(HiveHelper.showSteamMod, _enableSteamMod); 这实际上是在写入默认值
    if (!HiveHelper.containsKey(HiveHelper.showSteamMod)) {
      HiveHelper.put(HiveHelper.showSteamMod, _enableSteamMod);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invokeCallBack();
      setState(() {
        _loading = false;
      });
    });
  }

  bool _getEnableSteamModDefaultValue() {
    return Platform.isWindows || Platform.isLinux;
  }

  bool _loadHiveValue() {
    var modPath = HiveHelper.get(HiveHelper.modPath);
    var steamPath = HiveHelper.get(HiveHelper.steamModPath);
    var showSteamMod = HiveHelper.get(
      HiveHelper.showSteamMod,
      defaultValue: _getEnableSteamModDefaultValue(),
    );
    bool result = false;
    if (modPath != null) {
      setState(() {
        _modEditingController.text = modPath;
      });
      _checkModEditing(modPath);
    }
    setState(() {
      _enableSteamMod = showSteamMod;
    });

    if (showSteamMod) {
      if (steamPath != null) {
        setState(() {
          _steamModEditingController.text = steamPath;
        });
        _checkSteamModEditingError(steamPath);
        result = true;
      }
    } else {
      result = true;
    }
    return result;
  }

  List<Widget> _getCoreWidget() {
    return [
      TextField(
        controller: _modEditingController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          errorText: _modEditingErrorText,
          label: Text(AppLocalizations.of(context)!.modFolder),
          suffixIcon: IconButton(
            onPressed: () async {
              var path = await GlobalDepend.getFileSystemOperator()
                  .pickDirectory(context);
              if (path == null) {
                return;
              }
              setState(() {
                _modEditingController.text = path;
              });
              _checkModEditing(path);
            },
            icon: Icon(Icons.folder_outlined),
          ),
        ),
        onChanged: (text) => {_checkModEditing(text)},
      ),
      SizedBox(height: 8),
      if (Platform.isLinux || Platform.isWindows)
        Row(
          children: [
            Text(AppLocalizations.of(context)!.showModFromSteam),
            Expanded(child: SizedBox()),
            Switch(
              value: _enableSteamMod,
              onChanged: (b) {
                HiveHelper.put(HiveHelper.showSteamMod, b);
                setState(() {
                  _enableSteamMod = b;
                });
                _invokeCallBack();
              },
            ),
          ],
        ),
      if (Platform.isLinux || Platform.isWindows) SizedBox(height: 8),
      if (Platform.isLinux || Platform.isWindows)
        TextField(
          controller: _steamModEditingController,
          enabled: _enableSteamMod,
          decoration: InputDecoration(
            errorText: _steamModEditingErrorText,
            border: OutlineInputBorder(),
            label: Text(AppLocalizations.of(context)!.steamWorkshopFolder),
            suffixIcon: IconButton(
              onPressed: () async {
                var steamMod = await GlobalDepend.getFileSystemOperator()
                    .pickDirectory(context);
                if (steamMod == null) {
                  return;
                }
                setState(() {
                  _steamModEditingController.text = steamMod;
                });
                _checkSteamModEditingError(steamMod);
              },
              icon: Icon(Icons.folder_outlined),
            ),
          ),
          onChanged: (text) => {_checkSteamModEditingError(text)},
        ),
      if (Platform.isLinux || Platform.isWindows) SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: SizedBox()),
          TextButton(
            onPressed: () => {setDefaultPath(true)},
            child: Text(AppLocalizations.of(context)!.restoreToDefaultFolder),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(child: Column(children: _getCoreWidget())),
    );
  }

  //检查模组目录可能存在的错误
  void _checkModEditing(String text) async {
    if (text.isEmpty) {
      setState(() {
        _modEditingErrorText = AppLocalizations.of(context)!.invalidFolder;
      });
      _invokeCallBack();
      return;
    }

    if (await GlobalDepend.getFileSystemOperator().checkFolderAvailable(text)) {
      HiveHelper.put(HiveHelper.modPath, text);
      setState(() {
        _modEditingErrorText = null;
      });
    } else {
      setState(() {
        _modEditingErrorText = AppLocalizations.of(context)!.folderDoesNotExist;
      });
    }
    _invokeCallBack();
  }

  void _invokeCallBack() {
    if (widget.modPathConfigLegal == null) {
      return;
    }
    if (_modEditingController.text.isEmpty) {
      widget.modPathConfigLegal!.call(false);
      return;
    }
    if (_enableSteamMod) {
      if (_steamModEditingController.text.isEmpty) {
        widget.modPathConfigLegal!.call(false);
        return;
      }
      if (_steamModEditingErrorText != null) {
        widget.modPathConfigLegal!.call(false);
        return;
      }
    }
    widget.modPathConfigLegal!.call(_modEditingErrorText == null);
  }

  //检测Steam目录可能存在的错误
  void _checkSteamModEditingError(String text) async {
    if (text.isEmpty) {
      setState(() {
        _steamModEditingErrorText = AppLocalizations.of(context)!.invalidFolder;
      });
      _invokeCallBack();
      return;
    }
    if (await GlobalDepend.getFileSystemOperator().checkFolderAvailable(text)) {
      HiveHelper.put(HiveHelper.steamModPath, text);
      setState(() {
        _steamModEditingErrorText = null;
      });
    } else {
      setState(() {
        _steamModEditingErrorText = AppLocalizations.of(
          context,
        )!.folderDoesNotExist;
      });
    }
    _invokeCallBack();
  }

  void setDefaultPath(bool overwrite) async {
    final String? userHomePath = await GlobalDepend.getUserHomeDirectory();
    if (userHomePath == null) {
      return;
    }
    if (overwrite) {
      setState(() {
        _enableSteamMod = _getEnableSteamModDefaultValue();
      });
      HiveHelper.put(HiveHelper.showSteamMod, _enableSteamMod);
    }
    if (Platform.isLinux) {
      if (overwrite || _modEditingController.text.isEmpty) {
        setState(() {
          _modEditingController.text = p.join(
            userHomePath,
            ".local",
            "share",
            "Steam",
            "steamapps",
            "common",
            "Rusted Warfare",
            "mods",
            "units",
          );
          _checkModEditing(_modEditingController.text);
        });
      }
      if (overwrite || _steamModEditingController.text.isEmpty) {
        setState(() {
          _steamModEditingController.text = p.join(
            userHomePath,
            ".local",
            "share",
            "Steam",
            "steamapps",
            "workshop",
            "content",
            "647960",
          );
          _checkSteamModEditingError(_steamModEditingController.text);
        });
      }
    }
    if (Platform.isWindows) {
      final steamPath = await getSteamInstallPath();
      if (steamPath == null) {
        setState(() {
          _enableSteamMod = false;
        });
        return;
      }
      if (overwrite || _modEditingController.text.isEmpty) {
        final commonPath = p.join(
          steamPath,
          'steamapps',
          'common',
          'Rusted Warfare',
          'mods',
          'units',
        );
        setState(() {
          _modEditingController.text = commonPath;
          _checkModEditing(commonPath);
        });
      }
      if (overwrite || _steamModEditingController.text.isEmpty) {
        final workshopPath = p.join(
          steamPath,
          'steamapps',
          'workshop',
          'content',
          '647960',
        );
        setState(() {
          _steamModEditingController.text = workshopPath;
          _checkSteamModEditingError(workshopPath);
        });
      }
    }
  }

  //查询Steam的注册表
  Future<String?> getSteamInstallPath() async {
    final result = await Process.run('reg', [
      'query',
      r'HKCU\Software\Valve\Steam',
      '/v',
      'SteamPath',
    ]);

    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final match = RegExp(
        r'SteamPath\s+REG_SZ\s+(.+)',
        caseSensitive: false,
      ).firstMatch(output);
      if (match != null) {
        return match.group(1)?.trim().replaceAll("/", "\\");
      }
    }
    return null;
  }
}
