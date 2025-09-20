import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/databeans/recycle_bin_item.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

class RestoreDialog extends StatefulWidget {
  final RecycleBinItem recycleBinItem;
  final Function(RecycleBinItem) onRestore;
  const RestoreDialog({
    super.key,
    required this.recycleBinItem,
    required this.onRestore,
  });

  @override
  State<StatefulWidget> createState() {
    return _RestoreDialogState();
  }
}

class _RestoreDialogState extends State<RestoreDialog> {
  bool _exist = true;
  bool _restoreing = false;
  bool _cancel = false;
  String _restoreTip = "";
  double? _progress;
  String? _title;
  @override
  void initState() {
    super.initState();
    _loadExist();
  }

  void _loadExist() async {
    var fileOperator = GlobalDepend.getFileSystemOperator();
    var path = widget.recycleBinItem.path;
    if (path == null) {
      return;
    }
    bool newExist = await fileOperator.exist(path);
    setState(() {
      _exist = newExist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title ?? AppLocalizations.of(context)!.restore),
      content: SizedBox(
        width: 400,
        child: _restoreing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _progress,),
                  SizedBox(height: 8),
                  Text(
                    _restoreTip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              )
            : Text(
                _exist
                    ? AppLocalizations.of(
                        context,
                      )!.fileAlreadyExistsAtTheOriginalLocation
                    : sprintf(
                        AppLocalizations.of(context)!.restoreToOriginalPosition,
                        [
                          widget.recycleBinItem.name ??
                              AppLocalizations.of(context)!.none,
                          widget.recycleBinItem.path ??
                              AppLocalizations.of(context)!.none,
                        ],
                      ),
              ),
      ),
      actions: [
        TextButton(
          child: Text(
            _exist
                ? AppLocalizations.of(context)!.confirm
                : AppLocalizations.of(context)!.cancel,
          ),
          onPressed: () {
            if (_restoreing) {
              _cancel = true;
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        if (!_exist && !_restoreing)
          TextButton(
            onPressed: () async {
              var recycleBinPath = widget.recycleBinItem.recycleBinPath;
              var targetPath = widget.recycleBinItem.path;
              if (recycleBinPath == null || targetPath == null) {
                return;
              }
              setState(() {
                _progress = null;
                _restoreing = true;
                _restoreTip = "";
              });
              FileSystemOperator fileSystemOperator =
                  GlobalDepend.getFileSystemOperator();
              var isDir = await fileSystemOperator.isDir(recycleBinPath);
              if (isDir) {
                if (!await fileSystemOperator.exist(targetPath)) {
                  Directory(targetPath).create(recursive: true);
                }
                int max = widget.recycleBinItem.count ?? 0;
                int current = 0;
                await fileSystemOperator.list(recycleBinPath, (path) async {
                  if (_cancel) {
                    return true;
                  }
                  if (!await fileSystemOperator.isDir(path)) {
                    var fileName = p.basename(path);
                    current++;
                    setState(() {
                      _progress = current / max;
                      _restoreTip = sprintf(
                        AppLocalizations.of(context)!.moveToRecyclingBinMessage,
                        [current, max, fileName],
                      );
                    });
                    var relativePath = p.relative(path, from: recycleBinPath);
                    var destination = p.join(targetPath, relativePath);
                    var destDir = Directory(p.dirname(destination));
                    if (!await destDir.exists()) {
                      await destDir.create(recursive: true);
                    }
                    await fileSystemOperator.copyToPath(path, destination);
                    return false;
                  }
                  return false;
                }, recursive: true);
              } else {
                setState(() {
                  _progress = null;
                  _restoreTip = sprintf(
                    AppLocalizations.of(context)!.moveToRecyclingBinMessage,
                    [
                      1,
                      1,
                      widget.recycleBinItem.name ??
                          AppLocalizations.of(context)!.none,
                    ],
                  );
                });
                await fileSystemOperator.copyToPath(recycleBinPath, targetPath);
              }
              if (!_cancel) {
                  setState(() {
                      _progress = null;
                      _title = AppLocalizations.of(context)!.clear;
                      _restoreTip = AppLocalizations.of(context)!.cleaning;
                    });
                await fileSystemOperator.delete(
                  recycleBinPath,
                  recursive: true,
                );
                await GlobalDepend.removeRecycleBinItem(widget.recycleBinItem);
                widget.onRestore(widget.recycleBinItem);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _cancel
                          ? AppLocalizations.of(
                              context,
                            )!.restorationHasBeenCancelled
                          : AppLocalizations.of(context)!.restoredSuccessfully,
                    ),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.restore),
          ),
      ],
    );
  }
}
