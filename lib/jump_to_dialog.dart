import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import 'l10n/app_localizations.dart';

class JumpToDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _JumpToDialogStatus();
  }

  const JumpToDialog({super.key, required this.maxLine, this.onJump});

  final Function(int)? onJump;

  //最大行号
  final int maxLine;
}

class _JumpToDialogStatus extends State<JumpToDialog> {
  String _lineNumber = "";
  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.jumpTo),
      content: TextField(
        onChanged: (value) {
          setState(() {
            _lineNumber = value;
            final number = int.tryParse(value);
            _isValid = number != null && number > 0 && number <= widget.maxLine;
          });
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          helperText: sprintf(AppLocalizations.of(context)!.maxLineNumber, [
            widget.maxLine,
          ]),
          labelText: AppLocalizations.of(context)!.lineNumber,
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _isValid
              ? () {
                  widget.onJump?.call(int.parse(_lineNumber));
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}
