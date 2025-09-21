import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/file_reference.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../constant.dart';
import '../global_depend.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import '../pages/built_in_file_selector_page.dart';
import 'data_interpreter.dart';

class FileListInterpreter extends DataInterpreter {
  final Function(String) onRequestOpenFile;
  final String modPath;
  final String sourceFilePath;
  final int selectFileType;

  const FileListInterpreter({
    super.key,
    required this.selectFileType,
    required this.sourceFilePath,
    required this.modPath,
    required this.onRequestOpenFile,
    required super.keyValue,
    required super.onLineDataChange,
    super.codeData,
    super.codeInfo,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _FileListDataInterpreterStatus();
  }
}

class _FileListDataInterpreterStatus extends State<FileListInterpreter> {
  final List<FileReference> _fileReferenceList = List.empty(growable: true);
  final RegExp regExp = RegExp("^.+:[0-9]+(.[0-9]+)?\$");

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() async {
    setState(() {
      _fileReferenceList.clear();
    });
    String value = widget.keyValue.value;
    var splitList = value.split(',');
    for (var split in splitList) {
      var splitTrim = split.trim();
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
      if (fileReference == null) {
        continue;
      }
      setState(() {
        _fileReferenceList.add(fileReference);
      });
    }
  }

  void _onLineChange() {
    final StringBuffer stringBuffer = StringBuffer();
    if (_fileReferenceList.isNotEmpty) {
      for (FileReference fileRef in _fileReferenceList) {
        if (stringBuffer.length > 0) {
          stringBuffer.write(',');
        }
        stringBuffer.write(fileRef.data);
        if (fileRef.extra != null) {
          stringBuffer.write(fileRef.extra);
        }
      }
    }
    widget.keyValue.value = stringBuffer.toString();
    widget.onLineDataChange?.call(widget, widget.keyValue.getLineData());
  }

  @override
  Widget build(BuildContext context) {
    var description = widget.codeInfo?.description;
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          if (widget.displayLineNumber)
            Text(
              widget.lineNumber.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          if (widget.displayLineNumber) SizedBox(width: 8),
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
                if (description != null) SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.attachedFiles,
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
                              maxSelectCount: Constant.maxSelectCountUnlimited,
                              selectFileType: widget.selectFileType,
                            );
                          },
                        );
                        if (selectList == null) {
                          return;
                        }
                        for (String select in selectList) {
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
                            continue;
                          }
                          _fileReferenceList.add(fileReference);
                          _onLineChange();
                        }
                      },
                      icon: Icon(Icons.file_present_outlined),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _fileReferenceList.length,
                  itemBuilder: (context, index) {
                    var item = _fileReferenceList[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.extra == null
                                ? item.data
                                : item.data + item.extra!,
                            style: item.exist
                                ? null
                                : Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fileReferenceList.remove(item);
                            });
                            _onLineChange();
                          },
                          tooltip: AppLocalizations.of(context)!.remove,
                          icon: Icon(Icons.remove),
                        ),
                        if (item.exist)
                          IconButton(
                            onPressed: () {
                              widget.onRequestOpenFile(item.path);
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            )!.openAnExistingFile,
                            icon: Icon(Icons.open_in_new_outlined),
                          ),
                        if (!item.exist)
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.invalidCitation,
                                    ),
                                    content: Text(
                                      sprintf(
                                        AppLocalizations.of(
                                          context,
                                        )!.pointedNotExist,
                                        [item.path],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.confirm,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            )!.invalidCitation,
                            icon: Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    );
                  },
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
