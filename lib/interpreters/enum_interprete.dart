import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../databeans/enum_data.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class EnumInterprete extends DataInterpreter {
  const EnumInterprete({
    super.key,
    required super.keyValue,
    required super.onLineDataChange,
    super.codeData,
    super.codeInfo,
    super.arguments,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _EnumInterpreterStatus();
  }
}

class _EnumInterpreterStatus extends State<EnumInterprete> {
  List<EnumData?> _enumDataList = [];
  EnumData? _selected;

  @override
  void initState() {
    super.initState();
    final args = widget.arguments;
    if (args != null && args.isNotEmpty) {
      _enumDataList = args
          .split(',')
          .map((id) => CodeDataBase.getEnumData(id))
          .toList();
    }
    var lowerCase = widget.keyValue.value.toString().toLowerCase();
    for (EnumData? item in _enumDataList) {
      if (item == null) {
        continue;
      }
      var temLowerCase = item.value.toString().toLowerCase();
      if (temLowerCase == lowerCase) {
        _selected = item;
        break;
      }
    }
    if (_selected == null) {
      //如果没有找到匹配的数据，将用户写入的值作为一个枚举对象，不要覆盖它。
      var value = widget.keyValue.value.toString();
      var temporary = EnumData(id: value, key: value, value: value);
      _enumDataList.add(temporary);
      _selected = temporary;
    }
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
            child: DropdownButtonFormField<EnumData>(
              initialValue: _selected,
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
              items: _enumDataList
                  .whereType<EnumData>()
                  .map(
                    (e) => DropdownMenuItem<EnumData>(
                      value: e,
                      child: Text(e.key ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (EnumData? newValue) {
                if (newValue == null) {
                  return;
                }
                widget.keyValue.value = newValue.value;
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
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
                // widget.onLineDataChange?.call(widget, '');
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
