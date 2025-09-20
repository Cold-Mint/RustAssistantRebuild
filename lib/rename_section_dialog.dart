import 'package:flutter/material.dart';

import 'databeans/section_info.dart';
import 'l10n/app_localizations.dart';

class RenameSectionDialog extends StatefulWidget {
  const RenameSectionDialog({
    super.key,
    required this.value,
    required this.sectionInfo,
    required this.checkForRepetition,
    required this.onRenameSection,
  });

  final bool Function(String) checkForRepetition;
  final String value;
  final SectionInfo? sectionInfo;
  final Function(String) onRenameSection;

  @override
  State<StatefulWidget> createState() {
    return _RenameSectionStatus();
  }
}

class _RenameSectionStatus extends State<RenameSectionDialog> {
  String _text = "";
  String _prefixText = "";
  bool _isLegal = false;
  String? _errorInfo;
  final TextEditingController _textEditingController = TextEditingController();

  String _getFullSection() {
    StringBuffer stringBuffer = StringBuffer();
    var section = widget.sectionInfo?.section;
    if (section == null) {
      stringBuffer.write('[');
      stringBuffer.write(_prefixText);
      stringBuffer.write(_text);
      stringBuffer.write(']');
    } else {
      stringBuffer.write('[');
      stringBuffer.write(widget.sectionInfo?.section);
      stringBuffer.write('_');
      stringBuffer.write(_text);
      stringBuffer.write(']');
    }
    return stringBuffer.toString();
  }

  @override
  void initState() {
    super.initState();
    var lastIndexOf = widget.value.lastIndexOf("_");
    var translate = widget.sectionInfo?.translate;
    if (translate == null) {
      if (lastIndexOf > -1) {
        _prefixText = widget.value.substring(0, lastIndexOf + 1);
      } else {
        _prefixText = "";
      }
    } else {
      _prefixText = "${translate}_";
    }
    var section = widget.sectionInfo?.section;
    if (section == null) {
      if (lastIndexOf > -1) {
        _textEditingController.text = widget.value.substring(lastIndexOf + 1);
      } else {
        _textEditingController.text = widget.value;
      }
    } else {
      _textEditingController.text = widget.value.substring(section.length + 1);
    }
    _text = _textEditingController.text;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.rename),
      content: TextField(
        controller: _textEditingController,
        onChanged: (s) {
          setState(() {
            _text = s;
          });
          if (s.isEmpty) {
            setState(() {
              _isLegal = false;
              _errorInfo = null;
            });
            return;
          }
          bool result = widget.checkForRepetition.call(_getFullSection());
          if (result) {
            //重复
            setState(() {
              _isLegal = false;
              _errorInfo = AppLocalizations.of(context)!.repeatedSectionNames;
            });
          } else {
            //不重复
            setState(() {
              _isLegal = true;
              _errorInfo = null;
            });
          }
        },
        decoration: InputDecoration(
          errorText: _errorInfo,
          border: OutlineInputBorder(),
          labelText: AppLocalizations.of(context)!.newName,
          prefixText: _prefixText,
        ),
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: _isLegal
              ? () {
                  widget.onRenameSection.call(_getFullSection());
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(AppLocalizations.of(context)!.rename),
        ),
      ],
    );
  }
}
