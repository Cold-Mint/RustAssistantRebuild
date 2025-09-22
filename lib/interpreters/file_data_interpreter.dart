import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/databeans/file_reference.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/interpreters/data_interpreter.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:rust_assistant/pages/built_in_file_selector_page.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';

class FileDataInterpreter extends DataInterpreter {
  final String sourceFilePath;
  final String modPath;
  final bool supportAuto;
  final int selectFileType;

  const FileDataInterpreter({
    super.key,
    required super.keyValue,
    required this.sourceFilePath,
    required this.modPath,
    required this.selectFileType,
    required super.onLineDataChange,
    required this.supportAuto,
    super.codeData,
    super.codeInfo,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _FileDataInterpreterStatus();
  }
}

class _FileDataInterpreterStatus extends State<FileDataInterpreter>
    with WidgetsBindingObserver {
  FileReference? _fileReference;
  bool _load = true;
  final RegExp regExp = RegExp("^.+:[0-9]+(.[0-9]+)?\$");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFileReference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFileReference();
    }
  }

  void _loadFileReference() async {
    setState(() {
      _load = true;
    });
    String splitTrim = widget.keyValue.value.toString().trim();
    String? extra;
    if (regExp.hasMatch(splitTrim)) {
      //匹配到后面的音量，例如: ROOT:aut/1.ogg:0.6 ，匹配0.6
      var lastIndex = splitTrim.lastIndexOf(":");
      extra = splitTrim.substring(lastIndex);
      splitTrim = splitTrim.substring(0, lastIndex);
    }
    FileReference? fileReference = await FileReference.fromData(
      widget.sourceFilePath,
      widget.modPath,
      splitTrim,
      extra,
    );
    if (mounted) {
      setState(() {
        _fileReference = fileReference;
        _load = false;
      });
    }
  }

  @override
  void didUpdateWidget(FileDataInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _loadFileReference();
    }
  }

  Widget _getCoreWidget() {
    if (_load) {
      return CircularProgressIndicator();
    }
    if (_fileReference == null) {
      return SizedBox();
    }
    if (!_fileReference!.exist) {
      var pathType = CodeDataBase.getAssetsPathType(_fileReference!.data);
      return Wrap(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          SizedBox(width: 8),
          Text(
            sprintf(AppLocalizations.of(context)!.pointedNotExist, [
              pathType == Constant.assetsPathTypeNone
                  ? _fileReference!.path
                  : _fileReference!.data,
            ]),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      );
    }
    if (_fileReference!.fileType == FileTypeChecker.FileTypeUnknown) {
      return Text(_fileReference!.path);
    }
    var pathType = CodeDataBase.getAssetsPathType(_fileReference!.data);
    if (_fileReference!.fileType == FileTypeChecker.FileTypeImage) {
      return Tooltip(
        message: widget.keyValue.value.toString(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: pathType == Constant.assetsPathTypeNone
              ? Image.file(
                  File(_fileReference!.path),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  _fileReference!.path,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
        ),
      );
    }
    return SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    var description = widget.codeInfo?.description;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          if (widget.displayLineNumber)
            Row(
              children: [
                Text(
                  widget.lineNumber.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.codeInfo?.translate ?? widget.keyValue.key),
                SizedBox(height: 8),
                if (description != null)
                  HighlightLinkText(
                    text: description,
                    searchKeyword: "",
                    style: Theme.of(context).textTheme.bodySmall,
                    onSeeTap: (String code, String section) {
                      showDialog(
                        context: context,
                        builder: (_) => CodeDetailDialog(
                          code: code,
                          section: section,
                          searchKeyword: "",
                        ),
                      );
                    },
                  ),
                SizedBox(height: 8),
                _getCoreWidget(),
                Row(
                  children: [
                    Expanded(child: SizedBox()),
                    if (widget.supportAuto)
                      TextButton(
                        onPressed: widget.keyValue.value == Constant.auto
                            ? null
                            : () {
                                showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        AppLocalizations.of(context)!.auto,
                                      ),
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.wantToSetThisFileReferenceToAuto,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.cancel,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.confirm,
                                          ),
                                          onPressed: () {
                                            widget.keyValue.value =
                                                Constant.auto;
                                            widget.onLineDataChange?.call(
                                              widget,
                                              widget.keyValue.getLineData(),
                                            );
                                            _loadFileReference();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                        child: Text(AppLocalizations.of(context)!.auto),
                      ),
                    if (widget.supportAuto)
                      TextButton(
                        onPressed:
                            widget.keyValue.value == Constant.autoAnimated
                            ? null
                            : () {
                                showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.autoAnimated,
                                      ),
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.wantToSetThisFileReferenceToAutoAnimated,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.cancel,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.confirm,
                                          ),
                                          onPressed: () {
                                            widget.keyValue.value =
                                                Constant.autoAnimated;
                                            widget.onLineDataChange?.call(
                                              widget,
                                              widget.keyValue.getLineData(),
                                            );
                                            _loadFileReference();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                        child: Text(AppLocalizations.of(context)!.autoAnimated),
                      ),
                    TextButton(
                      onPressed: () async {
                        List<String>? selectList = await showModalBottomSheet(
                          showDragHandle: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BuiltInFileSelectorPage(
                              rootPath: widget.modPath,
                              selectFile: true,
                              checkBoxMode: Constant.checkBoxModeFile,
                              maxSelectCount: 1,
                              selectFileType: widget.selectFileType,
                            );
                          },
                        );
                        if (selectList == null || selectList.isEmpty) {
                          return;
                        }
                        var select = selectList.first;
                        FileReference? fileReference =
                            await FileReference.fromData(
                              widget.sourceFilePath,
                              widget.modPath,
                              GlobalDepend.switchToRelativePath(
                                widget.modPath,
                                widget.sourceFilePath,
                                select,
                              ),
                              null,
                            );
                        if (fileReference == null) {
                          return;
                        }
                        widget.keyValue.value = fileReference.data;
                        widget.onLineDataChange?.call(
                          widget,
                          widget.keyValue.getLineData(),
                        );
                        setState(() {
                          _fileReference = fileReference;
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.selectTheFile),
                    ),
                    TextButton(
                      onPressed: widget.keyValue.value == Constant.none
                          ? null
                          : () {
                              showDialog<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context)!.clear,
                                    ),
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.wantToClearThisFileReference,
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text(
                                          AppLocalizations.of(context)!.cancel,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                          AppLocalizations.of(context)!.clear,
                                        ),
                                        onPressed: () {
                                          widget.keyValue.value = Constant.none;
                                          widget.onLineDataChange?.call(
                                            widget,
                                            widget.keyValue.getLineData(),
                                          );
                                          _loadFileReference();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                      child: Text(AppLocalizations.of(context)!.clear),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.displayOperationOptions)
            IconButton(
              onPressed: () {
                widget.keyValue.isNote = true;
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
              tooltip: AppLocalizations.of(context)!.convertToAnnotations,
              icon: Icon(Icons.sync_alt),
            ),
          if (widget.displayOperationOptions)
            IconButton(
              tooltip: AppLocalizations.of(context)!.delete,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.delete),
                      content: Text(
                        sprintf(
                          AppLocalizations.of(context)!.doYouWantDeleteThisCode,
                          [widget.keyValue.getLineData()],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.cancel),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.delete),
                          onPressed: () {
                            widget.onLineDataChange?.call(widget, '');
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}
