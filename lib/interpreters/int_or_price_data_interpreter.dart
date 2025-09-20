import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/resource_ref.dart';
import 'package:rust_assistant/resource_config_dialog.dart';
import 'package:sprintf/sprintf.dart';

import '../code_detail_dialog.dart';
import '../highlight_link_text.dart';
import '../l10n/app_localizations.dart';
import 'data_interpreter.dart';

class IntORPriceDataInterpreter extends DataInterpreter {
  final List<ResourceRef> globalResource;
  final List<ResourceRef> Function() getLocalResource;
  final Function(String) onRequestOpenFile;

  const IntORPriceDataInterpreter({
    super.key,
    required super.keyValue,
    required this.globalResource,
    required this.getLocalResource,
    required super.onLineDataChange,
    required this.onRequestOpenFile,
    super.codeData,
    super.codeInfo,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _IntORPriceDataInterpreterStatus();
  }
}

class _IntORPriceDataInterpreterStatus
    extends State<IntORPriceDataInterpreter> {
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
  void didUpdateWidget(IntORPriceDataInterpreter oldWidget) {
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
                suffixIcon: IconButton(
                  onPressed: () async {
                    var result = await showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) {
                        return ResourceConfigDialog(
                          getLocalResource: widget.getLocalResource,
                          globalResource: widget.globalResource,
                          value: widget.keyValue.value,
                          onRequestOpenFile: widget.onRequestOpenFile,
                        );
                      },
                    );
                    if (result != null) {
                      _textEditingController.text = result;
                      widget.keyValue.value = result;
                      widget.onLineDataChange?.call(
                        widget,
                        widget.keyValue.getLineData(),
                      );
                    }
                  },
                  icon: Icon(Icons.menu_book_outlined),
                  tooltip: AppLocalizations.of(context)!.resourceAllocation,
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
