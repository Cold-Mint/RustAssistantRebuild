import 'package:flutter/material.dart';
import 'package:rust_assistant/dataSources/tag_data_source.dart';
import 'package:rust_assistant/search_multiple_selection_dialog.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class TagInterpreter extends DataInterpreter {
  final List<String> tagList;
  final bool enableAddDialog;

  const TagInterpreter({
    super.key,
    required super.keyValue,
    required super.onLineDataChange,
    required this.enableAddDialog,
    super.codeData,
    super.codeInfo,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
    required this.tagList
  });

  @override
  State<StatefulWidget> createState() {
    return _TagInterpreterStatus();
  }
}

class _TagInterpreterStatus extends State<TagInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();

  final List<String> _selectedTag = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.keyValue.value;
    var value = widget.keyValue.value.toString();
    generateSelectTag(value);
  }

  void generateSelectTag(String value) {
    setState(() {
      _selectedTag.clear();
    });
    if (value.isEmpty) {
      return;
    }
    var temArray = value.split(',');
    if (temArray.isEmpty) {
      return;
    }
    for (String item in temArray) {
      var trim = item.trim();
      if (trim.isNotEmpty) {
        setState(() {
          _selectedTag.add(trim);
        });
      }
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TagInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _textEditingController.text = widget.keyValue.value;
    }
  }

  List<Chip> getChipList() {
    final Map<String, int> tagCount = {};
    final List<Chip> chipList = [];
    for (String item in _selectedTag) {
      tagCount[item] = (tagCount[item] ?? 0) + 1;
      final isDuplicate = tagCount[item]! > 1;
      chipList.add(
        Chip(
          label: Tooltip(
            message: isDuplicate
                ? AppLocalizations.of(context)!.repeatedDefinition
                : "",
            child: isDuplicate
                ? Wrap(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        item,
                        style: TextStyle(
                          color: isDuplicate
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  )
                : Text(item),
          ),
        ),
      );
    }
    return chipList;
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
                TextField(
                  maxLines: null,
                  style: TextStyle(fontFamily: 'Mono'),
                  onChanged: (s) {
                    generateSelectTag(s);
                    widget.keyValue.value = s;
                    widget.onLineDataChange?.call(
                      widget,
                      widget.keyValue.getLineData(),
                    );
                  },
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: widget.enableAddDialog
                        ? IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                showDragHandle: true,
                                isScrollControlled: true,
                                context: context,
                                builder: (context) {
                                  TagDataSource tagDataSource = TagDataSource(
                                    AppLocalizations.of(context)!.addTags,
                                    AppLocalizations.of(context)!.searchByTitle,
                                    AppLocalizations.of(context)!.addTagsTip,
                                  );
                                  tagDataSource.existedList.addAll(
                                    _selectedTag,
                                  );
                                  tagDataSource.allList.addAll(widget.tagList);
                                  return SearchMultipleSelectionDialog(
                                    dataSource: tagDataSource,
                                    onSelected: (list) {
                                      final StringBuffer stringBuffer =
                                          StringBuffer();
                                      stringBuffer.write(
                                        _textEditingController.text,
                                      );
                                      for (var value in list) {
                                        if (value is! String) {
                                          continue;
                                        }
                                        if (stringBuffer.isEmpty) {
                                          stringBuffer.write(value);
                                        } else {
                                          var temStr = stringBuffer.toString();
                                          if (!temStr.endsWith(",")) {
                                            stringBuffer.write(',');
                                          }
                                          stringBuffer.write(value);
                                        }
                                      }
                                      var str = stringBuffer.toString();
                                      setState(() {
                                        _textEditingController.text = str;
                                        generateSelectTag(str);
                                      });
                                      widget.keyValue.value = str;
                                      widget.onLineDataChange?.call(
                                        widget,
                                        widget.keyValue.getLineData(),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.add),
                          )
                        : null,
                    labelText:
                        widget.codeInfo?.translate ?? widget.keyValue.key,
                    helper: description == null
                        ? null
                        : HighlightLinkText(
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
                  ),
                ),
                if (_selectedTag.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: getChipList()),
                ],
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
