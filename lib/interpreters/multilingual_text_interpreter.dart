import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/language_code.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class MultilingualTextInterpreter extends DataInterpreter {
  const MultilingualTextInterpreter({
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
    return _MultilingualTextInterpreterStatus();
  }
}

class _MultilingualTextInterpreterStatus
    extends State<MultilingualTextInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();
  String _autoCompleteText = "";

  //用于自动完成的语言代码数组
  final List<LanguageCode> _languageCodeList = List.empty(growable: true);
  String _languageCode = "";
  String _originKey = "";

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  void _updateData() {
    _languageCode = getLanguageCode(widget.keyValue.key) ?? "";
    var index = widget.keyValue.key.lastIndexOf("_");
    if (index > -1) {
      _originKey = widget.keyValue.key.substring(0, index);
    } else {
      _originKey = widget.keyValue.key;
    }
    _textEditingController.text = widget.keyValue.value;
  }

  void _didChangeDependencies() {
    //加载语言代码信息
    _languageCodeList.clear();
    String text = AppLocalizations.of(context)!.general;
    var generalLanguageCode = LanguageCode(translate: text, code: "");
    _languageCodeList.add(generalLanguageCode);
    for (var languageCode in CodeDataBase.getLanguageCodeList()) {
      if (languageCode.code == _languageCode.toLowerCase()) {
        text = _languageCodeToStr(languageCode);
      }
      _languageCodeList.add(languageCode);
    }
    _autoCompleteText = text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _didChangeDependencies();
  }

  String? getLanguageCode(String key) {
    var index = key.indexOf("_");
    if (index == -1) {
      return null;
    }
    return key.substring(index + 1);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  String _languageCodeToStr(LanguageCode languageCode) {
    StringBuffer stringBuffer = StringBuffer();
    var translate = languageCode.translate;
    if (translate != null && translate.isNotEmpty) {
      stringBuffer.write(translate);
    }
    var code = languageCode.code;
    if (code != null && code.isNotEmpty) {
      stringBuffer.write('(');
      stringBuffer.write(code);
      stringBuffer.write(')');
    }
    return stringBuffer.toString();
  }

  @override
  void didUpdateWidget(covariant MultilingualTextInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _updateData();
      _didChangeDependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    var description = widget.codeInfo?.description;
    return Padding(
      padding: EdgeInsets.all(8),
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
            child: Autocomplete<LanguageCode>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final input = textEditingValue.text.toLowerCase();
                return _languageCodeList.where((LanguageCode option) {
                  return _languageCodeToStr(
                    option,
                  ).toLowerCase().contains(input);
                });
              },
              onSelected: (LanguageCode selection) {
                _autoCompleteText = _languageCodeToStr(selection);
                setState(() {
                  _languageCode = selection.code ?? "";
                });
                if (_languageCode.isEmpty) {
                  widget.keyValue.key = _originKey;
                } else {
                  widget.keyValue.key = "${_originKey}_$_languageCode";
                }
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
              displayStringForOption: (LanguageCode option) =>
                  _languageCodeToStr(option),
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    fieldTextEditingController.text = _autoCompleteText;
                    fieldTextEditingController.selection =
                        TextSelection.fromPosition(
                          TextPosition(
                            offset: fieldTextEditingController.text.length,
                          ),
                        );
                    return TextField(
                      focusNode: focusNode,
                      controller: fieldTextEditingController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        helperText: _languageCode,
                        labelText: AppLocalizations.of(context)!.language,
                      ),
                    );
                  },
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              maxLines: null,
              style: TextStyle(fontFamily: 'Mono'),
              onChanged: (s) {
                widget.keyValue.value = s;
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
              controller: _textEditingController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: widget.codeInfo?.translate ?? widget.keyValue.key,
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
