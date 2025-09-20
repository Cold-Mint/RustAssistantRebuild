import 'package:flutter/material.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

class RenameDialog extends StatefulWidget {
  final String fileName;
  final String folderPath;
  final Function(String, String) onRename;

  const RenameDialog({
    super.key,
    required this.fileName,
    required this.folderPath,
    required this.onRename,
  });

  @override
  State<StatefulWidget> createState() {
    return _RenameDialogState();
  }
}

class _RenameDialogState extends State<RenameDialog> {
  final TextEditingController _textEditingController = TextEditingController();
  String _fileName = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.fileName;
    FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    _textEditingController.addListener(() async {
      setState(() {
        _fileName = _textEditingController.text;
      });
      var newPath = fileSystemOperator.join(
        widget.folderPath,
        GlobalDepend.getSecureFileName(_fileName),
      );
      if (_fileName.isNotEmpty &&
          await fileSystemOperator.exist(newPath) &&
          _fileName != widget.fileName) {
        if (mounted) {
          setState(() {
            _errorText = sprintf(
              AppLocalizations.of(context)!.fileRepeatedlyPrompts,
              [GlobalDepend.getSecureFileName(_fileName)],
            );
          });
        }
      } else {
        setState(() {
          _errorText = null;
        });
      }
    });
    _fileName = widget.fileName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.rename),
      content: TextField(
        controller: _textEditingController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _fileName.isEmpty || _errorText != null
              ? null
              : () {
                  var newPath = GlobalDepend.getFileSystemOperator().join(
                    widget.folderPath,
                    GlobalDepend.getSecureFileName(_fileName),
                  );
                  var oldPath = GlobalDepend.getFileSystemOperator().join(
                    widget.folderPath,
                    widget.fileName,
                  );
                  GlobalDepend.getFileSystemOperator().rename(oldPath, newPath);
                  widget.onRename(oldPath, newPath);
                  Navigator.pop(context, true);
                },
          child: Text(AppLocalizations.of(context)!.rename),
        ),
      ],
    );
  }
}
