import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:rust_assistant/databeans/resource_ref.dart';
import 'package:rust_assistant/databeans/unit_ref.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/pages/image_viewer.dart';
import 'package:rust_assistant/scrollable_tabBar_with_mouse_wheel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_depend.dart';
import '../l10n/app_localizations.dart';

import 'ini_editor_page.dart';

class WorkspacePage extends StatefulWidget {
  final List<String> openedFilePath;
  final int openedFileLen;
  final int targetTabIndex;
  final List<String> unsavedFilePath;
  final Map<String, String> pathToFileData;
  final Map<String, String> pathToFileName;
  final Map<String, int> pathToFileType;
  final List<String> tagList;
  final Function(String)? addUnsaved;
  final List<ResourceRef> globalResource;
  final Function(int) onTabIndexChange;
  final Function(String)? navigateToTheDirectory;
  final Function(String)? closeTag;
  final bool displayLineNumber;
  final bool displayOperationOptions;
  final Map<String, int> pathToMaxLineNumber;
  final Function onRequestOpenDrawer;
  final Function onRequestChangeLeftWidget;
  final Function(String) onRequestOpenFile;
  final Function(
    Function(String, String, bool, String, bool) onCreate, {
    String? folder,
  })
  onRequestShowCreateFileDialog;
  final String rootPath;
  final List<UnitRef> modUnit;

  const WorkspacePage({
    super.key,
    required this.rootPath,
    required this.openedFileLen,
    required this.globalResource,
    required this.openedFilePath,
    required this.unsavedFilePath,
    required this.addUnsaved,
    required this.targetTabIndex,
    required this.pathToFileData,
    required this.onTabIndexChange,
    required this.navigateToTheDirectory,
    required this.displayLineNumber,
    required this.pathToMaxLineNumber,
    required this.onRequestOpenDrawer,
    required this.onRequestShowCreateFileDialog,
    required this.displayOperationOptions,
    required this.onRequestOpenFile,
    required this.pathToFileName,
    required this.pathToFileType,
    required this.modUnit,
    required this.tagList,
    required this.onRequestChangeLeftWidget,
    required this.closeTag,
  });

  @override
  State<StatefulWidget> createState() {
    return _WorkspaceStatus();
  }
}

class _WorkspaceStatus extends State<WorkspacePage>
    with TickerProviderStateMixin {
  late List<String> _unsavedFilePath;
  late Map<String, String> _pathToFileData;
  TabController? _tabController;
  final FileSystemOperator _fileSystemOperator =
      GlobalDepend.getFileSystemOperator();

  @override
  void initState() {
    super.initState();
    _unsavedFilePath = widget.unsavedFilePath;
    _pathToFileData = widget.pathToFileData;
    if (widget.openedFileLen > 0) {
      //确保状态被销毁后，有文件处于打开状态，那么重建TabController。例如，从大屏幕切换到小屏幕，会销毁对象。那么我们在这里创建_tabController。
      _tabController = TabController(length: widget.openedFileLen, vsync: this);
      addListener();
    }
  }

  List<Widget> getTabs() {
    List<Widget> widgets = List.empty(growable: true);
    if (widget.openedFilePath.isNotEmpty) {
      for (var f in widget.openedFilePath) {
        List<MenuItemButton> menuItemButtonList = List.empty(growable: true);
        menuItemButtonList.add(
          MenuItemButton(
            requestFocusOnHover: false,
            onPressed: () async {
              widget.navigateToTheDirectory?.call(
                await _fileSystemOperator.dirname(f),
              );
            },
            child: Text(
              AppLocalizations.of(
                context,
              )!.navigateToTheDirectoryWhereTheFileIsLocated,
            ),
          ),
        );
        if (Platform.isWindows || Platform.isLinux) {
          menuItemButtonList.add(
            MenuItemButton(
              requestFocusOnHover: false,
              onPressed: () async {
                var uri = Uri.parse("file:${path.dirname(f)}");
                var finalContext = context;
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (finalContext.mounted) {
                    ScaffoldMessenger.of(finalContext).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(finalContext)!.fail),
                      ),
                    );
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.openItInTheFileManager),
            ),
          );
        }

        menuItemButtonList.add(
          MenuItemButton(
            requestFocusOnHover: false,
            onPressed: () async {
              widget.closeTag?.call(f);
            },
            child: Text(AppLocalizations.of(context)!.close),
          ),
        );

        var contains = _unsavedFilePath.contains(f);
        var tab = Tab(
          child: Row(
            children: [
              Text(widget.pathToFileName[f] ?? f),
              MenuAnchor(
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
                menuChildren: menuItemButtonList,
              ),
            ],
          ),
        );
        widgets.add(contains ? Badge(child: tab) : tab);
      }
    }
    return widgets;
  }

  List<Widget> getViews() {
    List<Widget> widgets = List.empty(growable: true);
    if (widget.openedFilePath.isNotEmpty) {
      for (var f in widget.openedFilePath) {
        var fileType = widget.pathToFileType[f];
        if (fileType == FileTypeChecker.FileTypeImage) {
          widgets.add(ImageViewer(path: f));
          continue;
        }
        if (fileType == FileTypeChecker.FileTypeText) {
          widgets.add(
            IniEditorPage(
              key: PageStorageKey<String>(f),
              sourceFilePath: f,
              globalResource: widget.globalResource,
              fileData: _pathToFileData.containsKey(f)
                  ? _pathToFileData[f]
                  : null,
              onDataChange: (data) {
                if (!_unsavedFilePath.contains(f)) {
                  widget.addUnsaved?.call(f);
                }
                setState(() {
                  _pathToFileData[f] = data;
                });
              },
              displayLineNumber: widget.displayLineNumber,
              onMaxLineNumberChange: (lineNumber) {
                widget.pathToMaxLineNumber[f] = lineNumber;
              },
              onRequestOpenDrawer: widget.onRequestOpenDrawer,
              onRequestChangeLeftWidget: widget.onRequestChangeLeftWidget,
              displayOperationOptions: widget.displayOperationOptions,
              onRequestOpenFile: widget.onRequestOpenFile,
              modPath: widget.rootPath,
              tagList: widget.tagList,
              modUnit: widget.modUnit,
            ),
          );
          continue;
        }
        widgets.add(
          Center(
            child: Text(AppLocalizations.of(context)!.fileNotSupportedOpening),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  void didUpdateWidget(covariant WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    //一定要使用openedFileLen进行比较，因为他们时两个不同的整数。使用widget.openedFilePath == oldWidget.openedFilePath是无效的他们属于同一引用。
    if (oldWidget.openedFileLen != widget.openedFileLen) {
      _tabController?.dispose();
      _tabController = TabController(length: widget.openedFileLen, vsync: this);
      addListener();
    }
    if (widget.openedFileLen > 0) {
      _tabController?.animateTo(widget.targetTabIndex);
    }
  }

  void addListener() {
    var finalTabController = _tabController;
    if (finalTabController == null) {
      return;
    }
    finalTabController.addListener(() {
      // 只有当动画完成时才触发回调，避免动画过程中的中间状态
      if (!finalTabController.indexIsChanging) {
        int selectedIndex = finalTabController.index;
        widget.onTabIndexChange(selectedIndex);
      }
    });
  }

  void onCreate(
    String folder,
    String path,
    bool asFolder,
    String fileName,
    bool writeTheNecessaryCode,
  ) {
    if (asFolder) {
      widget.onRequestOpenDrawer.call();
    } else {
      widget.onRequestOpenFile.call(path);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (widget.openedFileLen == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 添加图标
            Icon(
              Icons.folder_open,
              size: 48,
              color: Theme.of(context).iconTheme.color,
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.startQuickly,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => {
                widget.onRequestShowCreateFileDialog.call(onCreate),
              },
              child: Text(AppLocalizations.of(context)!.createNewFile),
            ),
            if (screenWidth < 600) SizedBox(height: 8),
            if (screenWidth < 600)
              TextButton(
                onPressed: () => {widget.onRequestOpenDrawer.call()},
                child: Text(AppLocalizations.of(context)!.openAnExistingFile),
              ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: widget.openedFileLen,
      child: Scaffold(
        appBar: Platform.isWindows || Platform.isLinux
            ? PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: ScrollableTabBarWithMouseWheel(
                  tabBar: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: getTabs(),
                  ),
                ),
              )
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: getTabs(),
              ),
        body: TabBarView(controller: _tabController, children: getViews()),
      ),
    );
  }
}
