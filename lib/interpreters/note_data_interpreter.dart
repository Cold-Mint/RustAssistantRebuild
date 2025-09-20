//用于解释注解。
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import '../l10n/app_localizations.dart';
import '../mod/ini_reader.dart';
import 'data_interpreter.dart';

class NoteDataInterpreter extends DataInterpreter {
  const NoteDataInterpreter({
    super.key,
    required super.keyValue,
    required super.onLineDataChange,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _NoteDataInterpreterStatus();
  }
}

class _NoteDataInterpreterStatus extends State<NoteDataInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.keyValue.value;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NoteDataInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _textEditingController.text = widget.keyValue.value;
    }
  }

  bool convertible(String value) {
    var trimValue = value.trim();
    if (trimValue.isEmpty) {
      return false;
    }
    if (trimValue.contains(":")) {
      return true;
    }
    return trimValue.startsWith('[') && trimValue.endsWith(']');
  }

  @override
  Widget build(BuildContext context) {
    var convertibleValue = convertible(widget.keyValue.value);
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
            child: TextField(
              style: TextStyle(fontFamily: 'Mono'),
              maxLines: null,
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
                prefixText: "#",
              ),
            ),
          ),
          if (convertibleValue && widget.displayOperationOptions)
            IconButton(
              onPressed: () {
                var lineData = widget.keyValue.value;
                widget.keyValue.update(IniReader.getKeyValue(lineData));
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
              tooltip: AppLocalizations.of(context)!.convertToCode,
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
                          AppLocalizations.of(
                            context,
                          )!.doYouWantDeleteThisComment,
                          [widget.keyValue.value],
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
