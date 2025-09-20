import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class FloatORTimeDataInterpreter extends DataInterpreter {
  final bool lockTime;

  const FloatORTimeDataInterpreter({
    super.key,
    required this.lockTime,
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
    return _FloatORTimeDataInterpreterStatus();
  }
}

class _FloatORTimeDataInterpreterStatus
    extends State<FloatORTimeDataInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _enableTime = false;

  @override
  void initState() {
    super.initState();
    if (widget.lockTime) {
      _enableTime = true;
    } else {
      _enableTime = widget.keyValue.value.toString().toLowerCase().endsWith(
        "s",
      );
    }
    if (_enableTime) {
      _textEditingController.text = widget.keyValue.value.substring(
        0,
        widget.keyValue.value.toString().length - 1,
      );
    } else {
      _textEditingController.text = widget.keyValue.value;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FloatORTimeDataInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      _textEditingController.text = widget.keyValue.value;
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
            child: TextField(
              style: TextStyle(fontFamily: 'Mono'),
              onChanged: (s) {
                if (_enableTime) {
                  widget.keyValue.value = "${s}s";
                } else {
                  widget.keyValue.value = s;
                }
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,}$')),
                // 只允许输入小数
              ],
              controller: _textEditingController,
              decoration: InputDecoration(
                suffixText: _enableTime
                    ? AppLocalizations.of(context)!.seconds
                    : null,
                suffixIcon: widget.lockTime
                    ? null
                    : IconButton(
                        tooltip: _enableTime
                            ? AppLocalizations.of(
                                context,
                              )!.disableTheUseOfSecondsAsTheUnit
                            : AppLocalizations.of(
                                context,
                              )!.enableSecondsAsTheUnit,
                        onPressed: () => {
                          setState(() {
                            _enableTime = !_enableTime;
                            if (_enableTime) {
                              widget.onLineDataChange?.call(
                                widget,
                                "${widget.keyValue.key}: ${_textEditingController.text}s",
                              );
                            } else {
                              widget.onLineDataChange?.call(
                                widget,
                                "${widget.keyValue.key}: ${_textEditingController.text}",
                              );
                            }
                          }),
                        },
                        icon: Icon(
                          _enableTime
                              ? Icons.timer_outlined
                              : Icons.timer_off_outlined,
                        ),
                      ),
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
