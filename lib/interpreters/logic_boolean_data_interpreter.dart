import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/logical_boolean_translate.dart';
import 'package:rust_assistant/interpreters/logical_boolean/value_logical_boolean_child_interpreter.dart';
import 'package:rust_assistant/search_multiple_selection_dialog.dart';
import 'package:sprintf/sprintf.dart';

import '../code_data_base.dart';
import '../code_detail_dialog.dart';
import '../dataSources/logic_boolean_data_source.dart';
import '../databeans/logical_boolean.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';
import 'logical_boolean/func_logical_boolean_child_interpreter.dart';

class LogicBooleanDataInterpreter extends DataInterpreter {
  const LogicBooleanDataInterpreter({
    super.key,
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
    return _LogicBooleanDataInterpreterState();
  }
}

class _LogicBooleanDataInterpreterState
    extends State<LogicBooleanDataInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> stringList = List.empty(growable: true);
  List<Widget> _presenterList = [];

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.keyValue.value;
    _presenterList = _generatePresenterList(widget.keyValue.value);
    _textEditingController.addListener(() {
      var text = _textEditingController.text;
      widget.keyValue.value = text;
      setState(() {
        _presenterList = _generatePresenterList(text);
        widget.onLineDataChange?.call(widget, widget.keyValue.getLineData());
      });
    });
  }

  @override
  void didUpdateWidget(LogicBooleanDataInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _textEditingController.text = widget.keyValue.value;
    }
  }

  List<Widget> _generatePresenterList(String text) {
    final list = <Widget>[];
    for (final token in text.split(' ')) {
      if (token.trim().isEmpty) continue;
      list.add(
        getLogicalBooleanChildInterpreter(
          token,
          CodeDataBase.matchLogicalBooleanByContent(token),
          CodeDataBase.matchLogicalBooleanTranslateByContent(token),
        ),
      );
    }
    return list;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Widget getLogicalBooleanChildInterpreter(
    String token,
    LogicalBoolean? logicalBoolean,
    LogicalBooleanTranslate? logicalBooleanTranslate,
  ) {
    if (logicalBoolean == null) {
      return ValueLogicalBooleanChildInterpreter(
        value: token,
        displayValue: logicalBooleanTranslate?.translate ?? token,
      );
    }
    var interpreter = logicalBoolean.interpreter;
    if (interpreter == null) {
      return ValueLogicalBooleanChildInterpreter(
        value: token,
        displayValue: logicalBooleanTranslate?.translate ?? token,
      );
    }
    if (interpreter == "func") {
      return FuncLogicalBooleanChildInterpreter(
        value: token,
        logicalBoolean: logicalBoolean,
        logicalBooleanTranslate: logicalBooleanTranslate,
      );
    }
    return ValueLogicalBooleanChildInterpreter(
      value: token,
      displayValue: logicalBooleanTranslate?.translate ?? token,
    );
  }

  Widget? getSuggest(BuildContext context, String text) {
    if (text.isEmpty) return null;

    var token = text.trim();
    var index = token.lastIndexOf(' ');
    if (index != -1) {
      token = token.substring(index + 1).trim();
    }

    if (token.isEmpty) return null;

    var logicalBoolean = CodeDataBase.findLogicalBooleanByName(token);
    if (logicalBoolean == null) {
      return null;
    }
    final name = logicalBoolean.name;
    if (name == null || !name.toLowerCase().startsWith(token.toLowerCase())) {
      return null;
    }

    final rule = logicalBoolean.rule;
    String? translate;
    if (rule != null) {
      final logicalBooleanTranslate =
          CodeDataBase.findLogicalBooleanTranslateByRule(rule);
      if (logicalBooleanTranslate != null) {
        translate = logicalBooleanTranslate.translate;
      }
    }

    final remainingText = name.substring(token.length);

    return GestureDetector(
      onTap: () {
        var lastIndex = _textEditingController.text.lastIndexOf(' ');
        if (logicalBoolean.isFunction == true) {
          setState(() {
            _textEditingController.text =
                "${_textEditingController.text.substring(0, lastIndex + 1)}$name()";
          });
        } else {
          setState(() {
            _textEditingController.text =
                _textEditingController.text.substring(0, lastIndex + 1) + name;
          });
        }
      },
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
          children: [
            // 高亮部分（token）
            TextSpan(
              text: token,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary, // 使用主题主色
                fontWeight: FontWeight.bold,
              ),
            ),
            // 剩余文本部分
            TextSpan(
              text: remainingText,
              style: Theme.of(context).textTheme.bodyMedium, // 使用主题普通文本样式
            ),
            // 翻译（括号）部分
            if (translate != null)
              TextSpan(
                text: " ($translate)",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
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
                  style: TextStyle(fontFamily: 'Mono'),
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
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
                ?getSuggest(context, _textEditingController.text),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          showDragHandle: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) {
                            final LogicBooleanDataSource
                            logicBooleanDataSource = LogicBooleanDataSource(
                              AppLocalizations.of(context)!.addFunction,
                              AppLocalizations.of(context)!.searchFunction,
                              AppLocalizations.of(context)!.addFunctionTip,
                            );
                            var logicalBooleanList =
                                CodeDataBase.getLogicalBooleanList();
                            for (LogicalBoolean logicalBoolean
                                in logicalBooleanList) {
                              var rule = logicalBoolean.rule;
                              var mixedLogicalBoolean = MixedLogicalBoolean(
                                logicalBoolean,
                                rule == null
                                    ? null
                                    : CodeDataBase.findLogicalBooleanTranslateByRule(
                                        rule,
                                      ),
                              );
                              logicBooleanDataSource.allList.add(
                                mixedLogicalBoolean,
                              );
                            }
                            return SearchMultipleSelectionDialog(
                              onSelected: (list) {
                                StringBuffer append = StringBuffer();
                                append.write(_textEditingController.text);
                                for (var element in list) {
                                  if (element is! MixedLogicalBoolean) {
                                    continue;
                                  }
                                  var appendString = append.toString();
                                  if (appendString.isNotEmpty &&
                                      !appendString.endsWith(" ")) {
                                    append.write(' ');
                                  }
                                  var logicalBoolean = element.logicalBoolean;
                                  var isFunction = logicalBoolean.isFunction;
                                  if (isFunction == null ||
                                      isFunction == false) {
                                    append.write(logicalBoolean.name);
                                  } else {
                                    append.write('${logicalBoolean.name}(');
                                    var argument = logicalBoolean.argument;
                                    if (argument != null &&
                                        argument.isNotEmpty) {
                                      var necessaryNumber = 0;
                                      for (var value in argument) {
                                        var isRequired = value.isRequired;
                                        if (isRequired != null && isRequired) {
                                          if (necessaryNumber > 0) {
                                            append.write(',');
                                          }
                                          append.write(value.name);
                                          append.write('=');
                                          append.write('0');
                                          necessaryNumber++;
                                        }
                                      }
                                    }
                                    append.write(')');
                                  }
                                }
                                var str = append.toString();
                                setState(() {
                                  _textEditingController.text = str;
                                  _presenterList = _generatePresenterList(str);
                                });
                              },
                              dataSource: logicBooleanDataSource,
                            );
                          },
                        );
                      },
                      tooltip: AppLocalizations.of(context)!.addFunction,
                      icon: Icon(Icons.functions_outlined),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _presenterList,
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
