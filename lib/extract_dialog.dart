import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:sprintf/sprintf.dart';
import 'package:archive/archive.dart'; // Add this import for archive functionality

class ExtractDialog extends StatefulWidget {
  final String path;
  final String name;
  final String targetDirectory;

  const ExtractDialog({
    super.key,
    required this.path,
    required this.name,
    required this.targetDirectory,
  });
  @override
  State<StatefulWidget> createState() {
    return ExtractDialogState();
  }
}

class ExtractDialogState extends State<ExtractDialog> {
  bool _deleteFile = true;
  //表示解压状态
  bool _decompressioning = false;
  //表示中途被用户取消
  bool _cancel = false;
  bool _error = false;
  String? _errorMessage;
  late String _targetPath;
  late bool _exist = true;
  String _nowFileName = "";
  double? _progress;

  @override
  void initState() {
    super.initState();
    var secureFileName = GlobalDepend.getSecureFileName(widget.name);
    if (secureFileName == widget.name) {
      var index = widget.name.lastIndexOf('.');
      if (index > -1) {
        secureFileName = widget.name.substring(0, index);
      } else {
        secureFileName = "${widget.name}_decompressed";
      }
    }
    _targetPath = p.join(widget.targetDirectory, secureFileName);
    _updateExist();
    if (HiveHelper.containsKey(
      HiveHelper.deleteOriginalFileAfterDecompression,
    )) {
      _deleteFile = HiveHelper.get(
        HiveHelper.deleteOriginalFileAfterDecompression,
        defaultValue: true,
      );
    }
  }

  void _updateExist() async {
    final bool newExist = await GlobalDepend.getFileSystemOperator().exist(
      _targetPath,
    );
    setState(() {
      _exist = newExist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _error
          ? Text(AppLocalizations.of(context)!.decompressionFailed)
          : Text(AppLocalizations.of(context)!.decompress),
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_error && !_decompressioning)
              Text(
                _exist
                    ? AppLocalizations.of(context)!.folderAlreadyExists
                    : sprintf(
                        AppLocalizations.of(
                          context,
                        )!.doYouLikeDecompressTheSourceFile,
                        [widget.name],
                      ),
              ),
            if (!_error && !_decompressioning && !_exist) SizedBox(height: 8),
            if (!_error && !_decompressioning && !_exist)
              Row(
                children: [
                  Checkbox(
                    value: _deleteFile,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _deleteFile = value;
                      });
                      HiveHelper.put(
                        HiveHelper.deleteOriginalFileAfterDecompression,
                        value,
                      );
                    },
                  ),
                  Text(AppLocalizations.of(context)!.deleteOriginalFile),
                ],
              ),
            if (!_error && _decompressioning)
              LinearProgressIndicator(value: _progress),
            if (!_error && _decompressioning) SizedBox(height: 8),
            if (!_error && _decompressioning)
              Text(
                _nowFileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            if (_error) Text(sprintf(AppLocalizations.of(context)!.pleaseSwitchToAnotherDecompression, [_errorMessage])),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            _exist
                ? AppLocalizations.of(context)!.confirm
                : _error
                ? AppLocalizations.of(context)!.close
                : AppLocalizations.of(context)!.cancel,
          ),
          onPressed: () {
            if (!_error && _decompressioning) {
              _cancel = true;
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        if (!_exist && !_decompressioning)
          TextButton(
            onPressed: () async {
              setState(() {
                _decompressioning = true;
                _progress = null;
              });
              final file = File(widget.path);
              setState(() {
                _nowFileName = AppLocalizations.of(context)!.readTheFile;
                _progress = null;
              });
              final bytes = await file.readAsBytes();
              try {
                final archive = ZipDecoder().decodeBytes(bytes);
                var currentIndex = 0;
                for (final file in archive) {
                  if (_cancel) {
                    break;
                  }
                  final String filePath = p.join(_targetPath, file.name);
                  if (file.isFile) {
                    currentIndex++;
                    setState(() {
                      _nowFileName = sprintf(
                        AppLocalizations.of(context)!.extractTip,
                        [currentIndex, archive.length, p.basename(file.name)],
                      );
                      _progress = currentIndex / archive.length;
                    });
                    final outFile = File(filePath)..createSync(recursive: true);
                    await outFile.writeAsBytes(file.content as List<int>);
                  }
                }

                if (!_cancel && _deleteFile) {
                  await GlobalDepend.moveToRecycleBin(widget.path);
                }
                if (context.mounted) {
                  if (_cancel) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.decompressionHasBeenCancelled,
                        ),
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                }
              } catch (e) {
                setState(() {
                  _error = true;
                  _errorMessage = e.toString();
                });
              }
            },
            child: Text(AppLocalizations.of(context)!.decompress),
          ),
      ],
    );
  }
}
