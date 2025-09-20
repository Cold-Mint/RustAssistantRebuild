import 'package:flutter/material.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class ClearRecycleBinDialog extends StatefulWidget {
  const ClearRecycleBinDialog({super.key, required this.onClear});
  final Function onClear;

  @override
  State<StatefulWidget> createState() {
    return _ClearRecycleBinDialogState();
  }
}

class _ClearRecycleBinDialogState extends State<ClearRecycleBinDialog> {
  bool _deleteing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _deleteing
            ? AppLocalizations.of(context)!.clear
            : AppLocalizations.of(context)!.clearRecycleBin,
      ),
      content: SizedBox(
        width: 400,
        child: _deleteing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.cleaning),
                ],
              )
            : Text(AppLocalizations.of(context)!.wantToClearRecycleBin),
      ),
      actions: [
        if (!_deleteing)
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        if (!_deleteing)
          TextButton(
            child: Text(AppLocalizations.of(context)!.clearRecycleBin),
            onPressed: () async {
              var recycleBinPath = await GlobalDepend.getRecycleBinDirectory();
              if (recycleBinPath == null) {
                return;
              }
              setState(() {
                _deleteing = true;
              });
              await GlobalDepend.getFileSystemOperator().delete(
                recycleBinPath,
                recursive: true,
              );
              await GlobalDepend.clearRecycleBinList();
              widget.onClear.call();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
      ],
    );
  }
}
