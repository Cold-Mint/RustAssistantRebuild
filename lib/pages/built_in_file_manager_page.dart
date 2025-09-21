import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/delete_file_dialog.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:rust_assistant/pages/rename_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constant.dart';
import '../global_depend.dart';
import '../l10n/app_localizations.dart';

class BuiltInFileManagerPage extends StatefulWidget {
  final String rootPath;
  final String currentPath;
  final Function(String)? onRequestOpenFile;
  final Function(String) onCurrentPathChange;
  final Future<bool> Function(
    Function(String, String, bool, String, bool) onCreate, {
    String? folder,
  })?
  onClickAddFile;
  final bool embeddedPattern;
  final int checkBoxMode;
  final Function(List<String>)? selectedPathsChange;
  final int maxSelectCount;
  final int selectFileType;
  final Function(String, String) onRename;
  final Function(String) onDelete;

  const BuiltInFileManagerPage({
    super.key,
    this.onClickAddFile,
    this.onRequestOpenFile,
    required this.checkBoxMode,
    required this.rootPath,
    required this.currentPath,
    required this.onCurrentPathChange,
    required this.embeddedPattern,
    required this.selectedPathsChange,
    required this.maxSelectCount,
    required this.selectFileType,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<StatefulWidget> createState() {
    return _BuiltInFileManagerPageStaus();
  }
}

class _BuiltInFileManagerPageStaus extends State<BuiltInFileManagerPage>
    with WidgetsBindingObserver {
  bool _loading = true;
  String _currentPath = "";
  final List<FileEntity> _fileSystemEntity = List.empty(growable: true);
  List<FileEntity> _filteredFileSystemEntity = List.empty(growable: true);
  final FileSystemOperator _fileSystemOperator =
      GlobalDepend.getFileSystemOperator();
  String? _errorInfo;
  final List<String> _selectedPaths = List<String>.empty(growable: true);
  late TextEditingController _textEditingController;
  String _searchKeyword = "";
  bool _clickAddFab = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();

    _textEditingController.addListener(() {
      setState(() {
        _searchKeyword = _textEditingController.text.trim();
        _filterFileList();
      });
    });

    WidgetsBinding.instance.addObserver(this);
    if (widget.currentPath == Constant.currentPathRefresh) {
      getFiles(widget.rootPath);
    } else {
      getFiles(widget.currentPath);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_clickAddFab) {
        _clickAddFab = false;
        return;
      }
      getFiles(_currentPath);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textEditingController.dispose();
    super.dispose();
  }

  void _filterFileList() {
    if (_searchKeyword.isEmpty) {
      _filteredFileSystemEntity = List.from(_fileSystemEntity);
    } else {
      _filteredFileSystemEntity = _fileSystemEntity.where((file) {
        return file.name.toLowerCase().contains(_searchKeyword.toLowerCase());
      }).toList();
    }
  }

  void getFiles(String path) async {
    setState(() {
      _loading = true;
      _fileSystemEntity.clear();
      _filteredFileSystemEntity.clear();
      _currentPath = path;
      _errorInfo = null;
    });

    bool exist = await _fileSystemOperator.exist(path);
    if (!exist) {
      setState(() {
        _loading = false;
        _fileSystemEntity.clear();
        _filteredFileSystemEntity.clear();
        _currentPath = path;
        _errorInfo = AppLocalizations.of(context)!.directoryDoesNotExist;
      });
      return;
    }
    final List<FileEntity> entities = List.empty(growable: true);
    await _fileSystemOperator.list(path, (uri) async {
      final FileEntity fileEntity = FileEntity();
      bool isDir = await _fileSystemOperator.isDir(uri);
      fileEntity.path = uri;
      fileEntity.name = await _fileSystemOperator.name(uri);
      if (!mounted) {
        return true;
      }
      fileEntity.isDirectory = isDir;
      if (!isDir) {
        var fileHeader = await FileTypeChecker.readFileHeader(uri);
        var fileType = FileTypeChecker.getFileType(uri, fileHeader: fileHeader);
        fileEntity.type = fileType;
        if (fileType == FileTypeChecker.FileTypeImage) {
          fileEntity.bytes = await _fileSystemOperator.readAsBytes(uri);
        }
      }
      entities.add(fileEntity);
      return false;
    }, recursive: false);

    entities.sort((a, b) {
      bool aIsDir = FileSystemEntity.isDirectorySync(a.path);
      bool bIsDir = FileSystemEntity.isDirectorySync(b.path);

      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;

      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _errorInfo = null;
        _fileSystemEntity.addAll(entities);
        _filterFileList();
        _loading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant BuiltInFileManagerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      if (widget.currentPath == Constant.currentPathRefresh) {
        getFiles(oldWidget.currentPath);
      } else {
        getFiles(widget.currentPath);
      }
    }
  }

  Widget _getCoreWidget() {
    if (_errorInfo != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorInfo!),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  getFiles(_currentPath);
                },
                child: Text(AppLocalizations.of(context)!.refresh),
              ),
              if (_currentPath != widget.rootPath)
                TextButton(
                  onPressed: () {
                    widget.onCurrentPathChange.call(widget.rootPath);
                  },
                  child: Text(AppLocalizations.of(context)!.home),
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _textEditingController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: AppLocalizations.of(context)!.searchByTitle,
              isDense: true,
            ),
          ),
        ),
        if (_currentPath != widget.rootPath)
          ListTile(
            onTap: () async {
              var newPath = await _fileSystemOperator.dirname(_currentPath);
              widget.onCurrentPathChange.call(newPath);
            },
            leading: Icon(Icons.folder_outlined),
            title: Text(".."),
          ),
        if (_filteredFileSystemEntity.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFileSystemEntity.length,
              itemBuilder: (context, index) {
                var fileSystemEntity = _filteredFileSystemEntity[index];
                var filePath = fileSystemEntity.path;
                return ListTile(
                  onTap: () async {
                    if (fileSystemEntity.isDirectory) {
                      setState(() {
                        _textEditingController.text = "";
                      });
                      widget.onCurrentPathChange.call(filePath);
                      return;
                    }

                    if (widget.checkBoxMode == Constant.checkBoxModeFile) {
                      if (widget.selectFileType ==
                              FileTypeChecker.FileTypeAll ||
                          widget.selectFileType == fileSystemEntity.type) {
                        _onCheckChange(filePath);
                      }
                      return;
                    }
                    widget.onRequestOpenFile?.call(filePath);
                  },
                  leading: GlobalDepend.getFileIcon(
                    fileSystemEntity.isDirectory,
                    fileSystemEntity.path,
                    fileSystemEntity.bytes,
                  ),
                  title: HighlightText(
                    text: fileSystemEntity.name,
                    searchKeyword: _searchKeyword,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: trailingIcon(fileSystemEntity),
                );
              },
            ),
          ),
        if (_filteredFileSystemEntity.isEmpty && _searchKeyword.isEmpty)
          Expanded(
            child: Center(
              child: Text(AppLocalizations.of(context)!.noFilesFolders),
            ),
          ),
        if (_filteredFileSystemEntity.isEmpty && _searchKeyword.isNotEmpty)
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noMatchingFileFolderWasFound,
              ),
            ),
          ),
      ],
    );
  }

  Widget? trailingIcon(FileEntity fileSystemEntity) {
    if (widget.checkBoxMode == Constant.checkBoxModeNone) {
      return MenuAnchor(
        menuChildren: [
          MenuItemButton(
            requestFocusOnHover: false,
            child: Text(AppLocalizations.of(context)!.rename),
            onPressed: () async {
              bool rename = await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return RenameDialog(
                    fileName: fileSystemEntity.name,
                    folderPath: p.dirname(fileSystemEntity.path),
                    onRename: widget.onRename,
                  );
                },
              );
              if (rename) {
                getFiles(_currentPath);
              }
            },
          ),
          if (Platform.isLinux || Platform.isWindows)
            MenuItemButton(
              requestFocusOnHover: false,
              child: Text(AppLocalizations.of(context)!.openItInTheFileManager),
              onPressed: () async {
                var folder = fileSystemEntity.path;
                if (!fileSystemEntity.isDirectory) {
                  //如果不是文件夹，那么获取文件所在目录
                  folder = p.dirname(fileSystemEntity.path);
                }
                final uri = Uri.parse("file:$folder");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.fail),
                      ),
                    );
                  }
                }
              },
            ),
          MenuItemButton(
            requestFocusOnHover: false,
            child: Text(AppLocalizations.of(context)!.delete),
            onPressed: () async {
              bool delete = await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return DeleteFileDialog(
                    name: fileSystemEntity.name,
                    path: fileSystemEntity.path,
                  );
                },
              );
              if (delete) {
                widget.onDelete.call(fileSystemEntity.path);
                getFiles(_currentPath);
              }
            },
          ),
        ],
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: Icon(Icons.more_vert_outlined),
          );
        },
      );
    }

    return fileSystemEntity.isDirectory ||
            (widget.selectFileType != FileTypeChecker.FileTypeAll &&
                widget.selectFileType != fileSystemEntity.type)
        ? null
        : widget.maxSelectCount == 1
        ? Radio<String>(
            value: fileSystemEntity.path,
            groupValue: _selectedPaths.isNotEmpty ? _selectedPaths.first : null,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _onCheckChange(fileSystemEntity.path);
            },
          )
        : Checkbox(
            value: _selectedPaths.contains(fileSystemEntity.path),
            onChanged: (b) {
              _onCheckChange(fileSystemEntity.path);
            },
          );
  }

  void _onCheckChange(String filePath) {
    if (widget.maxSelectCount == 1) {
      setState(() {
        _selectedPaths.clear();
        _selectedPaths.add(filePath);
        widget.selectedPathsChange?.call(_selectedPaths);
      });
      return;
    }
    setState(() {
      if (_selectedPaths.contains(filePath)) {
        _selectedPaths.remove(filePath);
      } else {
        _selectedPaths.add(filePath);
      }
    });
    widget.selectedPathsChange?.call(_selectedPaths);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (widget.embeddedPattern) {
      return _getCoreWidget();
    }
    return Scaffold(
      body: SafeArea(child: _getCoreWidget()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _clickAddFab = true;
          if (await widget.onClickAddFile?.call(
                onCreate,
                folder: _currentPath,
              ) ==
              true) {
            getFiles(_currentPath);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void onCreate(
    String folder,
    String path,
    bool asFolder,
    String fileName,
    bool writeTheNecessaryCode,
  ) {
    if (asFolder) {
      widget.onCurrentPathChange.call(path);
    } else {
      getFiles(folder);
      widget.onRequestOpenFile?.call(path);
    }
  }
}

class FileEntity {
  late String path;
  late String name;
  late int type;
  bool isDirectory = false;
  Uint8List? bytes;
}
