import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class BoolDataInterpreter extends DataInterpreter {
  const BoolDataInterpreter({
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
    return _BoolDataInterpreterStatus();
  }
}

class _BoolDataInterpreterStatus extends State<BoolDataInterpreter> {
  bool _enable = false;

  @override
  void initState() {
    super.initState();
    _enable = widget.keyValue.value == "true";
  }

  @override
  void didUpdateWidget(BoolDataInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _enable = widget.keyValue.value == "true";
    }
  }

  @override
  void dispose() {
    super.dispose();
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 文本区域占据剩余空间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.codeInfo?.translate ?? widget.keyValue.key,
                        softWrap: true, // 明确允许换行
                      ),
                      if (description != null) SizedBox(height: 4),
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
                    ],
                  ),
                ),
                // Switch 固定在右侧
                Switch(
                  value: _enable,
                  onChanged: (b) {
                    setState(() {
                      _enable = b;
                    });
                    widget.keyValue.value = b;
                    widget.onLineDataChange?.call(
                      widget,
                      widget.keyValue.getLineData(),
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
