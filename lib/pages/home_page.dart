import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/mod/mod.dart';
import 'package:rust_assistant/pages/import_mod_page.dart';
import 'package:rust_assistant/pages/mod_page.dart';
import 'package:rust_assistant/pages/recycle_bin_page.dart';
import 'package:rust_assistant/pages/settings_page.dart';

import '../l10n/app_localizations.dart';
import 'create_mod_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeStatus();
  }
}

class _HomeStatus extends State<HomePage> {
  int _selectedIndex = 0;
  bool _pathConfigError = false;
  bool _dragAndDropIndicator = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    MethodChannel flutterPlatform = MethodChannel(Constant.flutterChannel);
    flutterPlatform.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'importMod':
        //当app已启动，用户导入Mod，那么会调用这个函数。
        final filePath = call.arguments;
        _importMod([filePath]);
        break;
    }
  }

  Future _importMod(List<String> files) async {
    setState(() {
      _loading = true;
    });
    List<Mod> newMod = List.empty(growable: true);
    for (var file in files) {
      Mod? mod = await GlobalDepend.convertToMod(file);
      if (mod == null) {
        continue;
      }
      newMod.add(mod);
    }
    if (newMod.isEmpty && mounted) {
      setState(() {
        _loading = false;
      });
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.importMod),
            content: Text(
              AppLocalizations.of(context)!.modNotBeenResolvedFromSelectedPath,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          );
        },
      );
      return;
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ImportModPage(modList: newMod);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _dragAndDropIndicator = true;
        });
      },
      onDragUpdated: (details) {},
      onDragExited: (details) {
        setState(() {
          _dragAndDropIndicator = false;
        });
      },
      onDragDone: (details) async {
        var files = List<String>.empty(growable: true);
        for (var file in details.files) {
          if (file.path.isEmpty) {
            continue;
          }
          files.add(file.path);
        }
        if (files.isEmpty) {
          return;
        }
        await _importMod(files);
      },
      child: _loading
          ? Scaffold(
              body: Center(
                child: Text(
                  AppLocalizations.of(context)!.analysisInProgress,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            )
          : _dragAndDropIndicator
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download, size: 128),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.dragTheFileHere,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: Text(getTitle()),
                actions: [
                  if (_selectedIndex == 0)
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.importMod,
                      onPressed: () async {
                        var files = await GlobalDepend.getFileSystemOperator()
                            .pickFiles(context, null);
                        if (files == null || files.isEmpty) {
                          return;
                        }
                        await _importMod(files);
                      },
                      icon: Icon(Icons.file_upload_outlined),
                    ),
                  if (_selectedIndex == 0)
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.recycleBin,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecycleBinPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.recycling_outlined),
                    ),
                ],
              ),
              body: SafeArea(
                child: screenWidth > 600
                    ? Row(
                        children: [
                          NavigationRail(
                            leading: _pathConfigError
                                ? null
                                : FloatingActionButton(
                                    elevation: 0,
                                    onPressed: modWizard,
                                    child: const Icon(Icons.add),
                                  ),
                            onDestinationSelected: (i) => {
                              setState(() {
                                _selectedIndex = i;
                              }),
                            },
                            labelType: NavigationRailLabelType.all,
                            destinations: <NavigationRailDestination>[
                              NavigationRailDestination(
                                icon: Icon(Icons.insert_drive_file_outlined),
                                selectedIcon: Icon(Icons.insert_drive_file),
                                label: Text(AppLocalizations.of(context)!.mods),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings),
                                label: Text(
                                  AppLocalizations.of(context)!.settings,
                                ),
                              ),
                            ],
                            selectedIndex: _selectedIndex,
                          ),
                          Expanded(child: getContent()),
                        ],
                      )
                    : getContent(),
              ),
              bottomNavigationBar: screenWidth > 600
                  ? null
                  : NavigationBar(
                      onDestinationSelected: (i) => {
                        setState(() {
                          _selectedIndex = i;
                        }),
                      },
                      selectedIndex: _selectedIndex,
                      destinations: [
                        NavigationDestination(
                          icon: Icon(Icons.insert_drive_file_outlined),
                          selectedIcon: Icon(Icons.insert_drive_file),
                          label: AppLocalizations.of(context)!.mods,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: AppLocalizations.of(context)!.settings,
                        ),
                      ],
                    ),
              floatingActionButton:
                  screenWidth > 600 || _selectedIndex != 0 || _pathConfigError
                  ? null
                  : FloatingActionButton(
                      onPressed: modWizard,
                      child: const Icon(Icons.add),
                    ),
            ),
    );
  }

  void modWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return CreateModPage();
        },
      ),
    );
  }

  String getTitle() {
    if (_selectedIndex == 0) {
      return AppLocalizations.of(context)!.mods;
    }
    if (_selectedIndex == 1) {
      return AppLocalizations.of(context)!.settings;
    }
    return AppLocalizations.of(context)!.appName;
  }

  Widget getContent() {
    if (_selectedIndex == 0) {
      return ModPage(
        onClickCreateMod: modWizard,
        onPathConfigError: (value) {
          if (value == _pathConfigError) {
            return;
          }
          setState(() {
            _pathConfigError = value;
          });
        },
      );
    }
    return SettingsPage();
  }
}
