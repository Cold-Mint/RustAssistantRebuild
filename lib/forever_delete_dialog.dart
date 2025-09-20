
import 'package:flutter/material.dart';
import 'package:rust_assistant/databeans/recycle_bin_item.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

class ForeverDeleteDialog extends StatefulWidget {
  final RecycleBinItem recycleBinItem;
  final Function(RecycleBinItem) onDelete;

  const ForeverDeleteDialog({
    super.key,
    required this.recycleBinItem,
    required this.onDelete,
  });
  @override
  State<StatefulWidget> createState() {
    return _ForeverDeleteDialogState();
  }
}

class _ForeverDeleteDialogState extends State<ForeverDeleteDialog> {
  bool _deleteing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _deleteing
            ? AppLocalizations.of(context)!.clear
            : AppLocalizations.of(context)!.foreverDelete,
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
            : Text(
                sprintf(AppLocalizations.of(context)!.wantToForeverDelete, [
                  widget.recycleBinItem.name ??
                      AppLocalizations.of(context)!.none,
                ]),
              ),
      ),
      actions: [
        if (!_deleteing)
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        if (!_deleteing)
          TextButton(
            child: Text(AppLocalizations.of(context)!.delete),
            onPressed: () async {
              var recycleBinPath = widget.recycleBinItem.recycleBinPath;
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
              await GlobalDepend.removeRecycleBinItem(widget.recycleBinItem);
              widget.onDelete.call(widget.recycleBinItem);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
      ],
    );
  }
}
