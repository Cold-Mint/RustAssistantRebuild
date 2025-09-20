import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/section_info.dart';
import 'package:rust_assistant/interpreters/data_interpreter.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:rust_assistant/rename_section_dialog.dart';

class SectionInterpreter extends DataInterpreter {
  final SectionInfo? sectionInfo;
  final bool Function(String) checkForRepetition;
  final Function(String) editSequenceCallBack;
  final Function(int, String) addCallBack;

  const SectionInterpreter({
    super.key,
    required this.addCallBack,
    required this.editSequenceCallBack,
    required this.sectionInfo,
    required this.checkForRepetition,
    required super.keyValue,
    required super.onLineDataChange,
    required super.lineNumber,
    required super.displayLineNumber,
    required super.displayOperationOptions,
  });

  @override
  State<StatefulWidget> createState() {
    return _SectionInterpreterStatus();
  }
}

class _SectionInterpreterStatus extends State<SectionInterpreter> {
  String _getDisplaySection() {
    final StringBuffer stringBuffer = StringBuffer();
    var lastIndexOf = widget.keyValue.key.lastIndexOf('_');
    var translate = widget.sectionInfo?.translate;
    if (lastIndexOf > -1) {
      if (translate == null) {
        stringBuffer.write(widget.keyValue.key);
      } else {
        stringBuffer.write(translate);
        var section = widget.sectionInfo?.section;
        if (section == null) {
          stringBuffer.write(widget.keyValue.key.substring(lastIndexOf));
        } else {
          stringBuffer.write(widget.keyValue.key.substring(section.length));
        }
      }
    } else {
      if (translate == null) {
        stringBuffer.write(widget.keyValue.key);
      } else {
        stringBuffer.write(translate);
      }
    }
    return stringBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsetsGeometry.all(8),
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
            SizedBox(width: 8),
            Expanded(child: Text(_getDisplaySection())),
            if (widget.keyValue.key.contains("_") &&
                widget.displayOperationOptions)
              IconButton(
                tooltip: AppLocalizations.of(context)?.rename,
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return RenameSectionDialog(
                        value: widget.keyValue.key,
                        sectionInfo: widget.sectionInfo,
                        checkForRepetition: widget.checkForRepetition,
                        onRenameSection: (fullSection) {
                          widget.keyValue.key = fullSection;
                          widget.onLineDataChange?.call(widget, fullSection);
                        },
                      );
                    },
                  );
                },
                icon: Icon(Icons.edit_outlined),
              ),

            if (widget.displayOperationOptions)
              IconButton(
                tooltip: AppLocalizations.of(context)?.editingSequence,
                onPressed: () {
                  widget.editSequenceCallBack.call(widget.keyValue.key);
                },
                icon: Icon(Icons.format_list_bulleted_outlined),
              ),
            IconButton(
              tooltip: AppLocalizations.of(context)?.addCodeTitle,
              onPressed: () {
                widget.addCallBack.call(widget.lineNumber, widget.keyValue.key);
              },
              icon: Icon(Icons.add_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
