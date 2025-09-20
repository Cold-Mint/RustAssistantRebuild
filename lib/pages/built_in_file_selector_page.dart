import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/highlight_text.dart';
import 'package:sprintf/sprintf.dart';

import '../constant.dart';
import '../l10n/app_localizations.dart';
import 'built_in_file_manager_page.dart';

class BuiltInFileSelectorPage extends StatefulWidget {
  final String rootPath;
  final bool selectFile;
  final int checkBoxMode;
  final int maxSelectCount;
  final int selectFileType;

  const BuiltInFileSelectorPage({
    super.key,
    required this.rootPath,
    required this.selectFile,
    required this.checkBoxMode,
    required this.maxSelectCount,
    required this.selectFileType,
  });

  @override
  State<StatefulWidget> createState() {
    return _BuiltInFileSelectorPageStatus();
  }
}

class _BuiltInFileSelectorPageStatus extends State<BuiltInFileSelectorPage> {
  late String _currentPath;
  String _folderName = "";
  late FileSystemOperator _fileSystemOperator;
  List<String>? _selectList;
  int _segmentIndex = Constant.segmentIndexFile;
  String _searchKeyword = "";
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _fileSystemOperator = GlobalDepend.getFileSystemOperator();
    _currentPath = widget.rootPath;
    _updateFolderName();
  }

  void _updateFolderName() async {
    String newName = await _fileSystemOperator.name(_currentPath);
    setState(() {
      _folderName = newName;
    });
  }

  //获取已选中的数据长度
  int _getSelectLength() {
    if (_selectList == null) {
      return 0;
    }
    return _selectList!.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.selectFile
                      ? AppLocalizations.of(context)!.selectTheFile
                      : AppLocalizations.of(context)!.selectTheFolder,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentPath,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.selectFile &&
              widget.selectFileType == FileTypeChecker.FileTypeImage &&
              widget.maxSelectCount == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                width: double.infinity, // 占满宽度
                child: SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    ButtonSegment(
                      value: Constant.segmentIndexFile,
                      label: Text(AppLocalizations.of(context)!.file),
                      icon: Icon(Icons.insert_drive_file_outlined),
                    ),
                    ButtonSegment(
                      value: Constant.segmentIndexCore,
                      label: Text(AppLocalizations.of(context)!.core),
                      icon: Icon(Icons.memory_outlined),
                    ),
                    ButtonSegment(
                      value: Constant.segmentIndexShared,
                      label: Text(AppLocalizations.of(context)!.shared),
                      icon: Icon(Icons.share_outlined),
                    ),
                  ],
                  selected: <int>{_segmentIndex},
                  showSelectedIcon: false,
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _segmentIndex = newSelection.first;
                      _searchKeyword = "";
                      _textEditingController.text = ""; // 切换时清空选择
                    });
                  },
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_segmentIndex == Constant.segmentIndexFile) {
                  // 文件管理
                  return BuiltInFileManagerPage(
                    rootPath: widget.rootPath,
                    currentPath: _currentPath,
                    onCurrentPathChange: (String path) {
                      setState(() {
                        _currentPath = path;
                      });
                      _updateFolderName();
                    },
                    embeddedPattern: true,
                    checkBoxMode: widget.checkBoxMode,
                    selectedPathsChange: (List<String> selectList) {
                      setState(() {
                        _selectList = selectList;
                      });
                    },
                    maxSelectCount: widget.maxSelectCount,
                    selectFileType: widget.selectFileType,
                    onRename: (String p1, String p2) {},
                    onDelete: (String p1) {},
                  );
                } else {
                  final listData = _segmentIndex == Constant.segmentIndexCore
                      ? CodeDataBase.coreRes
                      : CodeDataBase.sharedRes;

                  // 过滤
                  final filteredList = listData
                      .where(
                        (item) =>
                            _searchKeyword.isEmpty ||
                            item.toLowerCase().contains(
                              _searchKeyword.toLowerCase(),
                            ),
                      )
                      .toList();

                  return Column(
                    children: [
                      // 搜索框
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: AppLocalizations.of(
                              context,
                            )!.searchByTitle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchKeyword = value;
                            });
                          },
                        ),
                      ),
                      if (filteredList.isEmpty && _searchKeyword.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noFilesFolders,
                            ),
                          ),
                        ),
                      if (filteredList.isEmpty && _searchKeyword.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.noMatchingFileFolderWasFound,
                            ),
                          ),
                        ),
                      if (filteredList.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              var assetsPath = CodeDataBase.toAssetsPath(
                                item,
                                _segmentIndex == Constant.segmentIndexCore
                                    ? Constant.assetsPathTypeCore
                                    : Constant.assetsPathTypeShared,
                              );
                              return ListTile(
                                leading: Image.asset(
                                  width: 48,
                                  height: 48,
                                  _segmentIndex == Constant.segmentIndexCore
                                      ? CodeDataBase.getCorePath(item)
                                      : CodeDataBase.getSharedPath(item),
                                ),
                                title: HighlightText(
                                  text: item,
                                  searchKeyword: _searchKeyword,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                trailing: Radio(
                                  value: assetsPath,
                                  groupValue:
                                      _selectList != null &&
                                          _selectList!.isNotEmpty
                                      ? _selectList?.first
                                      : null,
                                  onChanged: (b) {
                                    setState(() {
                                      _selectList = [assetsPath];
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectList = [assetsPath];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: SizedBox()),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: widget.selectFile && _getSelectLength() == 0
                    ? null
                    : () {
                        if (widget.selectFile) {
                          Navigator.of(context).pop(_selectList);
                        } else {
                          Navigator.of(context).pop(_currentPath);
                        }
                      },
                child: Text(
                  widget.selectFile
                      ? sprintf(
                          AppLocalizations.of(context)!.selectNumberFiles,
                          [_getSelectLength()],
                        )
                      : sprintf(AppLocalizations.of(context)!.selectObjet, [
                          _folderName,
                        ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
