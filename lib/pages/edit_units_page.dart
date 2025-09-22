import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/databeans/resource_ref.dart';
import 'package:rust_assistant/databeans/unit_template.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/mod/ini_reader.dart';
import 'package:rust_assistant/mod/mod.dart';
import 'package:rust_assistant/operation_dialog.dart';
import 'package:rust_assistant/pages/built_in_file_manager_page.dart';
import 'package:rust_assistant/pages/work_space_page.dart';
import 'package:rust_assistant/text_difference.dart';
import 'package:sprintf/sprintf.dart';
import 'package:window_manager/window_manager.dart';

import '../constant.dart';
import '../create_file_of_folder_dialog.dart';
import '../databeans/visual_analytics_result.dart';
import '../l10n/app_localizations.dart';
import '../project_analyzer.dart';
import 'analytics_dialog.dart';

class EditUnitsPage extends StatefulWidget {
  const EditUnitsPage({super.key, required this.mod});

  final Mod mod;

  @override
  State<StatefulWidget> createState() {
    return _EditUnitsPageState();
  }
}

class _EditUnitsPageState extends State<EditUnitsPage>
    with WidgetsBindingObserver, WindowListener {
  final FocusNode _focusNode = FocusNode();
  final List<String> _openedFilePath = List.empty(growable: true);
  final List<String> _unsavedFilePath = List.empty(growable: true);
  final List<ResourceRef> _globalResource = List.empty(growable: true);
  String? _currentPath;
  final Map<String, String> _pathToFileData = {};
  int _targetTabIndex = 0;
  late ProjectAnalyzer _projectAnalyzer;
  final ValueNotifier<bool> isAnalyzingNotifier = ValueNotifier(false);
  final ValueNotifier<String> analyzingProgressNotifier = ValueNotifier("");
  bool _displayLineNumber = false;
  bool _displayOperationOptions = true;
  final Map<String, int> _pathToMaxLineNumber = {};
  final Map<String, String> _pathToFileName = {};
  final Map<String, int> _pathTofileType = {};
  final FileSystemOperator _fileSystemOperator =
      GlobalDepend.getFileSystemOperator();
  bool _firstDid = true;
  String _indexIsBeingUpdated = "%d %s";
  bool _cancelAnalytics = false;
  List<String> _tagList = List.empty();
  bool _autoSave = true;
  bool _showLeftWidget = true;

  //自动扫描项目并构建索引。
  bool _automaticIndexConstruction = !Platform.isAndroid;

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
    if (HiveHelper.containsKey(HiveHelper.displayOperationOptions)) {
      _displayOperationOptions = HiveHelper.get(
        HiveHelper.displayOperationOptions,
      );
    }
    if (HiveHelper.containsKey(HiveHelper.toggleLineNumber)) {
      _displayLineNumber = HiveHelper.get(HiveHelper.toggleLineNumber);
    }
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    _projectAnalyzer = ProjectAnalyzer(
      widget.mod.path,
      GlobalDepend.getFileSystemOperator(),
    );
    loadGlobalRes();
  }

  void _doAnalyze(BuildContext buildContext) {
    _projectAnalyzer.analyze(
      AppLocalizations.of(buildContext)!,
      _onStartAnalyze,
      _progress,
      _onFinishAnalyze,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //在安卓平台，显示/隐藏软键盘会调用didChangeDependencies方法
    if (_firstDid) {
      _firstDid = false;
      _indexIsBeingUpdated = AppLocalizations.of(context)!.indexIsBeingUpdated;
      if (_automaticIndexConstruction) {
        _doAnalyze(context);
      }
    }
  }

  void loadGlobalRes() async {
    var allUnitsTemplate = p.join(widget.mod.path, Constant.allUnitsTemplate);
    bool allUnitsExists =
        await FileSystemEntity.type(allUnitsTemplate) !=
        FileSystemEntityType.notFound;
    setState(() {
      _globalResource.clear();
    });
    if (allUnitsExists) {
      IniReader allUnitsReader = IniReader(
        await File(allUnitsTemplate).readAsString(),
      );
      var allSection = allUnitsReader.getAllSection();
      if (allSection.isEmpty) {
        return;
      }
      for (var sectionName in allSection) {
        var finalContext = context;
        var name = GlobalDepend.getSectionPrefix(sectionName).toLowerCase();
        if (name == "global_resource" || name == "resource") {
          if (!finalContext.mounted) {
            return;
          }
          var last = GlobalDepend.getSectionSuffix(sectionName);
          var language = GlobalDepend.getLanguage(finalContext);
          String? displayName = allUnitsReader
              .getKeyValueFromSection(sectionName, "displayName_$language")
              ?.value;
          displayName ??= allUnitsReader
              .getKeyValueFromSection(sectionName, "displayName")
              ?.value;
          if (last.isNotEmpty) {
            setState(() {
              _globalResource.add(
                ResourceRef(
                  name: last,
                  path: allUnitsTemplate,
                  globalResource: name == "global_resource",
                  displayName: displayName,
                ),
              );
            });
          }
        }
      }
    }
  }

  Future<bool> _performSave() async {
    if (_openedFilePath.isEmpty) return false;
    final nowOpened = _openedFilePath[_targetTabIndex];
    if (!_unsavedFilePath.contains(nowOpened)) {
      return false;
    }
    final newText = _pathToFileData[nowOpened];
    var name = await _fileSystemOperator.name(nowOpened);
    if (newText != null) {
      await _fileSystemOperator.writeFile(
        await _fileSystemOperator.dirname(nowOpened),
        name,
        newText,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sprintf(AppLocalizations.of(context)!.fileHasBeenSaved, [name]),
          ),
        ),
      );
    }
    setState(() {
      _unsavedFilePath.remove(nowOpened);
    });
    var finalContext = context;
    if (_automaticIndexConstruction && finalContext.mounted) {
      _doAnalyze(finalContext);
    }
    //额外的条件，如果保存的是allUnits
    var allUnitsTemplate = p.join(widget.mod.path, Constant.allUnitsTemplate);
    if (nowOpened == allUnitsTemplate) {
      loadGlobalRes();
    }
    return true;
  }

  Future<void> _showSourceDiff() async {
    if (_openedFilePath.isEmpty) return;
    final nowOpened = _openedFilePath[_targetTabIndex];
    final fileContent = await _fileSystemOperator.readAsString(nowOpened);
    if (!mounted) return;
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.basename(nowOpened),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextDifference(
                original: fileContent ?? "",
                newText: _pathToFileData[nowOpened] ?? fileContent ?? "",
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRequestOpenFile(String path) async {
    var index = _openedFilePath.indexOf(path);
    var fileName = await _fileSystemOperator.name(path);
    var fileHeader = await FileTypeChecker.readFileHeader(path);
    var fileType = FileTypeChecker.getFileType(path, fileHeader: fileHeader);
    if (index < 0) {
      setState(() {
        _openedFilePath.add(path);
        _pathToFileName[path] = fileName;
        _pathTofileType[path] = fileType;
        _targetTabIndex = _openedFilePath.length - 1;
      });
    } else {
      setState(() {
        _targetTabIndex = index;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_automaticIndexConstruction) {
        _doAnalyze(context);
      }
    } else if (state == AppLifecycleState.paused) {
      //仅限安卓和ios
      _performAutoSave();
    }
  }

  void _performAutoSave() {
    if (_autoSave) {
      _performSave();
    }
  }

  void _onFinishAnalyze(VisualAnalyticsResult? result) {
    if (!mounted) {
      return;
    }
    setState(() {
      isAnalyzingNotifier.value = false;
      if (result != null) {
        _tagList = result.tagList;
      }
    });
  }

  void _onStartAnalyze() {
    _cancelAnalytics = false;
    setState(() {
      isAnalyzingNotifier.value = true;
    });
  }

  bool _progress(int index, String fileName) {
    if (!mounted) {
      return true;
    }
    setState(() {
      analyzingProgressNotifier.value = sprintf(_indexIsBeingUpdated, [
        index,
        fileName,
      ]);
    });
    return _cancelAnalytics;
  }

  //当显示操作对话框
  Future<bool> showOperationDialogBox(
    Function(String, String, bool, String, bool) onCreate, {
    String? folder,
  }) async {
    String rootFolder = widget.mod.path;
    if (folder != null) {
      rootFolder = folder;
    }
    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return OperationDialog(
          folder: rootFolder,
          isRoot: rootFolder == widget.mod.path,
          onCreateNewFile: () async {
            await showCreateFileOrFolderDialog(onCreate, folder: rootFolder);
          },
          onCreateModInfo: () async {
            await _doCreateFile(
              GlobalDepend.getFileSystemOperator().join(
                rootFolder,
                Constant.modInfoFileName,
              ),
              false,
              Constant.modInfoFileName,
              true,
              null,
              rootFolder,
              Constant.modInfoFileName,
              onCreate,
            );
          },
          onCreateAllUnitsTemplate: () async {
            await _doCreateFile(
              GlobalDepend.getFileSystemOperator().join(
                rootFolder,
                Constant.allUnitsTemplate,
              ),
              false,
              Constant.allUnitsTemplate,
              true,
              null,
              rootFolder,
              Constant.allUnitsTemplate,
              onCreate,
            );
          },
        );
      },
    );
  }

  Future<void> showCreateFileOrFolderDialog(
    Function(String, String, bool, String, bool) onCreate, {
    String? folder,
  }) async {
    String rootFolder = widget.mod.path;
    if (folder != null) {
      rootFolder = folder;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateFileOfFolderDialog(
        folder: rootFolder,
        onCreate:
            (
              path,
              asFolder,
              fileName,
              createdFromUnitTemplate,
              templates,
              inputText,
            ) async {
              await _doCreateFile(
                path,
                asFolder,
                fileName,
                createdFromUnitTemplate,
                templates,
                rootFolder,
                inputText,
                onCreate,
              );
            },
      ),
    );
  }

  Future<void> _doCreateFile(
    String path,
    bool asFolder,
    String fileName,
    bool createdFromUnitTemplate,
    Templates? templates,
    String rootFolder,
    String inputText,
    Function(String, String, bool, String, bool) onCreate,
  ) async {
    final FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    if (asFolder) {
      await fileSystemOperator.mkdir(rootFolder, fileName);
    } else {
      final StringBuffer stringBuffer = StringBuffer();
      if (createdFromUnitTemplate) {
        var unitName = fileName;
        var symbolIndex = fileName.lastIndexOf(".");
        if (symbolIndex > 0) {
          unitName = fileName.substring(0, symbolIndex);
        }
        if (fileName.toLowerCase() == Constant.modInfoFileName) {
          var folderName = await fileSystemOperator.name(rootFolder);
          stringBuffer.write("[mod]\ntitle: ");
          stringBuffer.write(folderName);
          stringBuffer.write("\nminVersion:1.13");
        } else if (fileName.toLowerCase() == Constant.allUnitsTemplate) {
          stringBuffer.write("[core]");
        } else if (templates != null) {
          var inputName = inputText;
          var symbolIndex = inputName.lastIndexOf('.');
          if (symbolIndex > -1) {
            inputName = inputName.substring(0, symbolIndex);
          }
          var path = templates.path;
          if (path != null) {
            var templatesData = await rootBundle.loadString(path);
            stringBuffer.write(
              templatesData
                  .replaceAll("{UNIT_NAME}", unitName)
                  .replaceAll("{INPUT_NAME}", inputName),
            );
          }
        }
      }
      //不要动这里，必须调用写文件的方法
      await fileSystemOperator.writeFile(
        rootFolder,
        fileName,
        stringBuffer.toString(),
      );
      var finalContext = context;
      if (_automaticIndexConstruction && finalContext.mounted) {
        _doAnalyze(finalContext);
      }
    }
    onCreate.call(
      rootFolder,
      path,
      asFolder,
      fileName,
      createdFromUnitTemplate,
    );
  }

  Widget getLeft() {
    return Builder(
      builder: (context) {
        return BuiltInFileManagerPage(
          rootPath: widget.mod.path,
          currentPath: _currentPath ?? widget.mod.path,
          onRequestOpenFile: (path) {
            Scaffold.of(context).closeDrawer();
            _onRequestOpenFile(path);
          },
          onCurrentPathChange: (str) {
            setState(() {
              _currentPath = str;
            });
          },
          onClickAddFile: showOperationDialogBox,
          embeddedPattern: false,
          checkBoxMode: Constant.checkBoxModeNone,
          selectedPathsChange: null,
          maxSelectCount: Constant.maxSelectCountUnlimited,
          selectFileType: FileTypeChecker.FileTypeAll,
          onRename: (String oldPath, String newPath) async {
            var isDir = await _fileSystemOperator.isDir(newPath);
            if (isDir) {
              final affectedPaths = _openedFilePath
                  .where((p) => p.startsWith(oldPath))
                  .toList();
              for (final oldSubPath in affectedPaths) {
                final newSubPath = oldSubPath.replaceFirst(oldPath, newPath);
                var fileName = await _fileSystemOperator.name(newSubPath);
                setState(() {
                  _openedFilePath.remove(oldSubPath);
                  _openedFilePath.add(newSubPath);
                  if (_unsavedFilePath.contains(oldSubPath)) {
                    _unsavedFilePath.remove(oldSubPath);
                    _unsavedFilePath.add(newSubPath);
                  }
                  final data = _pathToFileData.remove(oldSubPath);
                  if (data != null) {
                    _pathToFileData[newSubPath] = data;
                  }
                  _pathToFileName.remove(oldSubPath);
                  _pathToFileName[newSubPath] = fileName;
                  var oldType = _pathTofileType[oldSubPath];
                  _pathTofileType.remove(oldSubPath);
                  if (oldType != null) {
                    _pathTofileType[newSubPath] = oldType;
                  }
                });
              }
              return;
            }
            var fileName = await _fileSystemOperator.name(newPath);
            setState(() {
              _openedFilePath.remove(oldPath);
              _openedFilePath.add(newPath);
              if (_unsavedFilePath.contains(oldPath)) {
                _unsavedFilePath.remove(oldPath);
                _unsavedFilePath.add(newPath);
              }
              String? oldData = _pathToFileData[oldPath];
              _pathToFileData.remove(oldPath);
              if (oldData != null) {
                _pathToFileData[newPath] = oldData;
              }
              _pathToFileName.remove(oldPath);
              _pathToFileName[newPath] = fileName;
              var oldType = _pathTofileType[oldPath];
              _pathTofileType.remove(oldPath);
              if (oldType != null) {
                _pathTofileType[newPath] = oldType;
              }
            });
          },
          onDelete: (String path) {
            _closeTag(path);
          },
        );
      },
    );
  }

  void _closeTag(String path) {
    setState(() {
      _openedFilePath.remove(path);
      _targetTabIndex = _openedFilePath.length - 1;
      _unsavedFilePath.remove(path);
      _pathToFileData.remove(path);
      _pathToFileName.remove(path);
      _pathTofileType.remove(path);
    });
  }

  Widget getRight() {
    return Builder(
      builder: (c) {
        return WorkspacePage(
          openedFileLen: _openedFilePath.length,
          globalResource: _globalResource,
          openedFilePath: _openedFilePath,
          unsavedFilePath: _unsavedFilePath,
          addUnsaved: (s) {
            setState(() {
              _unsavedFilePath.add(s);
            });
          },
          pathToFileData: _pathToFileData,
          targetTabIndex: _targetTabIndex,
          onTabIndexChange: (index) {
            setState(() {
              _targetTabIndex = index;
            });
          },
          navigateToTheDirectory: (path) {
            setState(() {
              _currentPath = path;
            });
            Scaffold.of(c).openDrawer();
          },
          displayLineNumber: _displayLineNumber,
          displayOperationOptions: _displayOperationOptions,
          pathToMaxLineNumber: _pathToMaxLineNumber,
          onRequestOpenDrawer: () {
            Scaffold.of(c).openDrawer();
          },
          onRequestShowCreateFileDialog: showCreateFileOrFolderDialog,
          onRequestOpenFile: (path) {
            //需要请求刷新侧边栏
            setState(() {
              _currentPath = Constant.currentPathRefresh;
            });
            _onRequestOpenFile(path);
          },
          pathToFileName: _pathToFileName,
          pathToFileType: _pathTofileType,
          rootPath: widget.mod.path,
          tagList: _tagList,
          onRequestChangeLeftWidget: () {
            setState(() {
              _showLeftWidget = !_showLeftWidget;
            });
          },
          closeTag: (String p1) {
            _closeTag(p1);
          },
        );
      },
    );
  }

  @override
  void onWindowBlur() {
    _performAutoSave();
  }

  @override
  void dispose() {
    isAnalyzingNotifier.dispose();
    _focusNode.dispose();
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setDisplayOperationOptions(bool value) {
    setState(() {
      _displayOperationOptions = value;
    });
    HiveHelper.put(HiveHelper.displayOperationOptions, value);
  }

  void _setDisplayLineNumber(bool value) {
    setState(() {
      _displayLineNumber = value;
    });
    HiveHelper.put(HiveHelper.toggleLineNumber, value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editUnit),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_outlined),
              onPressed: () {
                Navigator.pop(context);
              },
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.globalSearch,
            icon: ValueListenableBuilder<bool>(
              valueListenable: isAnalyzingNotifier,
              builder: (context, isAnalyzing, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.search_outlined, size: isAnalyzing ? 18 : 24),
                    if (isAnalyzing)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                showDragHandle: true,
                context: context,
                builder: (context) {
                  return ValueListenableBuilder<String>(
                    builder: (context, runTip, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: isAnalyzingNotifier,
                        builder: (context, isRunning, _) {
                          return AnalyticsDialog(
                            result: _projectAnalyzer.lastResult,
                            isRuning: isRunning,
                            onRequestOpenFile: _onRequestOpenFile,
                            onCancelAnalytics: () {
                              _cancelAnalytics = true;
                            },
                            onRescan: () {
                              _doAnalyze(context);
                            },
                          );
                        },
                      );
                    },
                    valueListenable: analyzingProgressNotifier,
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.saveAction,
            onPressed: _openedFilePath.isEmpty ? null : _performSave,
            icon: const Icon(Icons.save_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.moreActions,
            onSelected: (value) {
              if (value == 'toggle_line_number') {
                _setDisplayLineNumber(!_displayLineNumber);
              } else if (value == 'show_source_diff') {
                _showSourceDiff.call();
              } else if (value == 'display_operation_options') {
                _setDisplayOperationOptions(!_displayOperationOptions);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_line_number',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.toggleLineNumber),
                    Switch(
                      value: _displayLineNumber,
                      onChanged: (b) {
                        Navigator.pop(context);
                        _setDisplayLineNumber(b);
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'display_operation_options',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.displayOperationOptions),
                    Switch(
                      value: _displayOperationOptions,
                      onChanged: (b) {
                        Navigator.pop(context);
                        _setDisplayOperationOptions(b);
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'show_source_diff',
                enabled: _openedFilePath.isNotEmpty,
                child: Text(AppLocalizations.of(context)!.showSourceDiff),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      drawer: screenWidth > 600 ? null : Drawer(child: getLeft()),
      body: screenWidth > 600
          ? Row(
              children: [
                if (_showLeftWidget) SizedBox(width: 300, child: getLeft()),
                Expanded(child: getRight()),
              ],
            )
          : Column(children: [Expanded(child: getRight())]),
    );
  }
}
