import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class OperationDialog extends StatefulWidget {
  const OperationDialog({
    super.key,
    required this.folder,
    required this.isRoot,
    required this.onCreateNewFile,
    required this.onCreateModInfo,
    required this.onCreateAllUnitsTemplate,
  });
  final String folder;
  final Future<void> Function() onCreateNewFile;
  final Future<void> Function() onCreateModInfo;
  final Future<void> Function() onCreateAllUnitsTemplate;
  final bool isRoot;

  @override
  State<StatefulWidget> createState() {
    return OperationDialogState();
  }
}

class OperationDialogState extends State<OperationDialog> {
  bool _copying = false;
  bool _canCreateModInfo = false;
  bool _canCreateAllUnitsTemplate = false;

  @override
  void initState() {
    super.initState();
    initCanCreate();
  }

  void initCanCreate() async {
    if (!widget.isRoot) {
      return;
    }
    FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    bool modInfoExist = await fileSystemOperator.exist(
      fileSystemOperator.join(widget.folder, Constant.modInfoFileName),
    );
    setState(() {
      _canCreateModInfo = !modInfoExist;
    });
    bool allUnitsTemplateExist = await fileSystemOperator.exist(
      fileSystemOperator.join(widget.folder, Constant.allUnitsTemplate),
    );
    setState(() {
      _canCreateAllUnitsTemplate = !allUnitsTemplateExist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.add),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_canCreateModInfo && !_copying)
            ListTile(
              title: Text(AppLocalizations.of(context)!.createModInfo),
              onTap: () async {
                if (context.mounted) {
                  Navigator.pop(context, false);
                }
                await widget.onCreateModInfo.call();
              },
            ),
          if (_canCreateAllUnitsTemplate && !_copying)
            ListTile(
              title: Text(AppLocalizations.of(context)!.createAllTemplate),
              onTap: () async {
                if (context.mounted) {
                  Navigator.pop(context, false);
                }
                await widget.onCreateAllUnitsTemplate.call();
              },
            ),
          if (!_copying)
            ListTile(
              title: Text(AppLocalizations.of(context)!.createFileOrFolder),
              onTap: () async {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
                await widget.onCreateNewFile.call();
              },
            ),
          if (!_copying)
            ListTile(
              title: Text(AppLocalizations.of(context)!.importFile),
              onTap: () async {
                FileSystemOperator fileSystemOperator =
                    GlobalDepend.getFileSystemOperator();
                List<String>? pickFile = await fileSystemOperator.pickFiles(
                  context,
                  widget.folder,
                );
                if (pickFile == null) {
                  return;
                }
                setState(() {
                  _copying = true;
                });
                for (var file in pickFile) {
                  var destination = p.join(
                    widget.folder,
                    GlobalDepend.getSecureFileName(p.basename(file)),
                  );
                  await fileSystemOperator.copyToPath(file, destination);
                }
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          if (_copying) LinearProgressIndicator(),
          if (_copying) SizedBox(height: 8),
          if (_copying) Text(AppLocalizations.of(context)!.copyFileing),
        ],
      ),
      actions: [
        if (!_copying)
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
      ],
    );
  }
}
