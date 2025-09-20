import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/color_picker_dialog.dart';
import 'package:rust_assistant/interpreters/data_interpreter.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';

class ColorInterpreter extends DataInterpreter {
  const ColorInterpreter({
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
    return _ColorInsterpreterStatus();
  }
}

class _ColorInsterpreterStatus extends State<ColorInterpreter> {
  final TextEditingController _textEditingController = TextEditingController();
  Color? _color;

  @override
  void initState() {
    super.initState();
    var newText = widget.keyValue.value.trim().replaceFirst('#', '');
    _textEditingController.text = newText;
    _color = _parseColor(newText);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ColorInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyValue.key != widget.keyValue.key) {
      var newText = widget.keyValue.value.trim().replaceFirst('#', '');
      _textEditingController.text = newText;
      setState(() {
        _color = _parseColor(newText);
      });
    }
  }

  /// 打开颜色选择器
  Future<void> _pickColor(BuildContext context) async {
    Color? picked = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: _color ?? Colors.black),
    );
    if (picked != null) {
      // 生成 6 位 RGB（不带 alpha）
      final hex = picked
          .toARGB32()
          .toRadixString(16)
          .padLeft(6, '0')
          .toUpperCase();
      _textEditingController.text = hex;
      widget.keyValue.value = "#$hex";
      widget.onLineDataChange?.call(widget, widget.keyValue.getLineData());
      setState(() {
        _color = _parseColor(hex);
      });
    }
  }

  //src = ee30a7 返回 Colors.black（rgb = null）
  Color _parseColor(String src) {
    final hex = src.trim().replaceAll('#', ''); // 去掉所有 #
    switch (hex.length) {
      case 6:
        // 6 位 RGB → 补全 0xFF 作为 Alpha
        final rgb = int.tryParse('FF$hex', radix: 16);
        return rgb != null ? Color(rgb) : Colors.black;
      case 8:
        // 8 位 ARGB
        final argb = int.tryParse(hex, radix: 16);
        return argb != null ? Color(argb) : Colors.black;
      default:
        return Colors.black;
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
              maxLines: null,
              maxLength: 8,
              style: TextStyle(fontFamily: 'Mono'),
              onChanged: (s) {
                widget.keyValue.value = "#$s";
                widget.onLineDataChange?.call(
                  widget,
                  widget.keyValue.getLineData(),
                );
                setState(() {
                  _color = _parseColor(s);
                });
              },
              controller: _textEditingController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              ],
              decoration: InputDecoration(
                prefixText: "#",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: AppLocalizations.of(context)!.selectColor,
                  icon: Icon(Icons.color_lens, color: _color),
                  onPressed: () => _pickColor(context),
                ),
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
