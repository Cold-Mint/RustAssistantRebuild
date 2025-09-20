import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:rust_assistant/delete_file_dialog.dart';
import 'package:rust_assistant/extract_dialog.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:rust_assistant/mod/mod.dart';
import 'package:rust_assistant/pages/path_config_page.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import 'edit_units_page.dart';

class ModPage extends StatefulWidget {
  final Function onClickCreateMod;
  final Function(bool) onPathConfigError;

  const ModPage({
    super.key,
    required this.onClickCreateMod,
    required this.onPathConfigError,
  });

  @override
  State<StatefulWidget> createState() {
    return _ModPageStatus();
  }
}

class _ModPageStatus extends State<ModPage>
    with WidgetsBindingObserver, RouteAware {
  bool _loading = true;
  final List<Mod> _modList = List.empty(growable: true);
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  List<Mod> _filteredMods = [];
  VoidCallback? _onClickFunction;
  String? _errorInfo;
  String? _errorButtonText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMod();
  }

  bool _isSubscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isSubscribed) {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null) {
        routeObserver.subscribe(this, modalRoute);
        _isSubscribed = true;
      }
    }
  }

  Future<void> _loadModFromFolder(String folderPath) async {
    final FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    await fileSystemOperator.list(folderPath, (uri) async {
      var name = await fileSystemOperator.name(uri);
      if (name.toLowerCase() == 'custom_units_here.txt') {
        return false;
      }
      final mod = Mod(uri);
      await mod.load();
      setState(() {
        _modList.add(mod);
      });
      return false;
    }, recursive: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMod();
    }
  }

  Future<void> _loadMod() async {
    setState(() {
      _modList.clear();
      _filteredMods.clear();
      _loading = true;
      _errorInfo = null;
      _errorButtonText = null;
      _onClickFunction = null;
    });

    if (!await GlobalDepend.checkPathNormal()) {
      widget.onPathConfigError.call(true);
      setState(() {
        _modList.clear();
        _filteredMods.clear();
        _loading = false;
        _errorInfo = AppLocalizations.of(context)!.pathIsUnavailable;
        _errorButtonText = AppLocalizations.of(context)!.configuration;
        _onClickFunction = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(AppLocalizations.of(context)!.pathConfig),
                  ),
                  body: PathConfigPage(),
                );
              },
            ),
          );
        };
      });
      return;
    }
    widget.onPathConfigError.call(false);

    try {
      final modPath = HiveHelper.get(HiveHelper.modPath);
      await _loadModFromFolder(modPath);
      if (HiveHelper.get(HiveHelper.showSteamMod)) {
        final steamModPath = HiveHelper.get(HiveHelper.steamModPath);
        await _loadModFromFolder(steamModPath);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorInfo = e.toString();
      });
      debugPrint('Error loading mods: $e');
      return;
    }

    setState(() {
      _updateFilteredMods();
      _loading = false;
      _errorInfo = null;
      _errorButtonText = null;
      _onClickFunction = null;
    });
  }

  void _updateFilteredMods() {
    if (_searchKeyword.isEmpty) {
      _filteredMods = List.from(_modList);
    } else {
      _filteredMods = _modList.where((mod) {
        final name = mod.modName?.toLowerCase() ?? '';
        return name.contains(_searchKeyword);
      }).toList();
    }
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchKeyword = keyword;
      _updateFilteredMods();
    });
  }

  void _clickMod(Mod mod) {
    if (!mod.isDirectory) {
      final modPath = HiveHelper.get(HiveHelper.modPath);
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => ExtractDialog(
          targetDirectory: modPath,
          path: mod.path,
          name: mod.modName ?? AppLocalizations.of(context)!.none,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return EditUnitsPage(mod: mod);
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      routeObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadMod();
  }

  void openItInTheFileManager(Mod mod) async {
    var modPath = mod.path;
    if (!mod.isDirectory) {
      //如果不是文件夹，那么获取文件所在目录
      modPath = path.dirname(modPath);
    }
    final uri = Uri.parse("file:$modPath");
    var finalContext = context;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (finalContext.mounted) {
        ScaffoldMessenger.of(finalContext).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(finalContext)!.fail)),
        );
      }
    }
  }

  List<MenuItemButton> _getMenuItem(BuildContext context, Mod mod) {
    var menuItem = <MenuItemButton>[];
    if (Platform.isWindows || Platform.isLinux) {
      menuItem.add(
        MenuItemButton(
          requestFocusOnHover: false,
          onPressed: () => openItInTheFileManager(mod),
          child: Text(AppLocalizations.of(context)!.openItInTheFileManager),
        ),
      );
    }
    if (mod.steamId != null) {
      menuItem.add(
        MenuItemButton(
          requestFocusOnHover: false,
          child: Text(
            AppLocalizations.of(context)!.visitTheSteamWorkshopHomepage,
          ),
          onPressed: () async {
            var steamId = mod.steamId;
            final uri = Uri.parse(
              "https://steamcommunity.com/sharedfiles/filedetails/?id=$steamId",
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.fail)),
                );
              }
            }
          },
        ),
      );
    }
    menuItem.add(
      MenuItemButton(
        requestFocusOnHover: false,
        onPressed: () async {
          await showDialog<bool>(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return DeleteFileDialog(
                path: mod.path,
                name: mod.modName ?? path.basename(mod.path),
              );
            },
          );
        },
        child: Text(AppLocalizations.of(context)!.delete),
      ),
    );

    return menuItem;
  }

  @override
  Widget build(BuildContext rootContext) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorInfo != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 垂直方向居中
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
              child: Text(
                _errorInfo!,
                textAlign: TextAlign.center, // 文本水平方向居中
              ),
            ),
            if (_onClickFunction != null && _errorButtonText != null)
              SizedBox(height: 16),
            if (_onClickFunction != null && _errorButtonText != null)
              FilledButton(
                onPressed: _onClickFunction!,
                child: Text(_errorButtonText!),
              ),
          ],
        ),
      );
    }
    if (_modList.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //添加合适的图标
          Icon(Icons.folder_open, size: 64),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noModWasFound,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  _loadMod();
                },
                child: Text(AppLocalizations.of(context)!.refresh),
              ),
              TextButton(
                onPressed: () {
                  widget.onClickCreateMod.call();
                },
                child: Text(AppLocalizations.of(context)!.createMod),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (text) => _onSearchChanged(),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchByTitle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        if (_filteredMods.isEmpty)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noMatchingModWasFound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.pleaseTryUsingOtherKeywords),
              ],
            ),
          ),
        if (_filteredMods.isNotEmpty)
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey<String>('modList'),
              itemCount: _filteredMods.length,
              itemBuilder: (context, index) {
                var mod = _filteredMods[index];
                var modName = mod.modName;
                var modDescription = mod.modDescription;
                return Card.filled(
                  child: ListTile(
                    onTap: () {
                      _clickMod(mod);
                    },
                    trailing: MenuAnchor(
                      builder: (context, controller, child) {
                        return IconButton(
                          icon: const Icon(Icons.more_vert),
                          tooltip: AppLocalizations.of(
                            rootContext,
                          )!.moreActions,
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                        );
                      },
                      menuChildren: _getMenuItem(context, mod),
                    ),
                    leading: GlobalDepend.getIcon(context, mod),
                    title: HighlightText(
                      text: modName ?? AppLocalizations.of(context)!.none,
                      searchKeyword: _searchKeyword,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      modDescription ?? AppLocalizations.of(context)!.none,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
