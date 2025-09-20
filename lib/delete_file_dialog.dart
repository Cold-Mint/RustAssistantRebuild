import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

import 'constant.dart';
import 'global_depend.dart';
import 'l10n/app_localizations.dart';

class DeleteFileDialog extends StatefulWidget {
  final String path;
  final String name;

  const DeleteFileDialog({super.key, required this.path, required this.name});

  @override
  State<DeleteFileDialog> createState() => _DeleteFileDialogState();
}

class _DeleteFileDialogState extends State<DeleteFileDialog> {
  int _moveStatus = Constant.moveToRecycleBinStatusReady;
  int _total = 0;
  int _current = 0;
  String _fileName = "";
  bool _continueMove = true;

  Widget _getContent() {
    if (_moveStatus == Constant.moveToRecycleBinStatusReady) {
      // doYouWantDelete
      return Text(
        sprintf(AppLocalizations.of(context)!.doYouWantDelete, [widget.name]),
      );
    }
    if (_moveStatus == Constant.moveToRecycleBinStatusScan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: null),
          SizedBox(height: 8),
          Text(
            sprintf(AppLocalizations.of(context)!.statisticsFiles, [_total]),
          ),
        ],
      );
    }
    if (_moveStatus == Constant.moveToRecycleBinStatusCopy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: (_total == 0) ? null : _current / _total,
          ),
          SizedBox(height: 8),
          Text(
            sprintf(AppLocalizations.of(context)!.moveToRecyclingBinMessage, [
              _current,
              _total,
              _fileName,
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      );
    }
    if (_moveStatus == Constant.moveToRecycleBinStatusDelete) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: null),
          SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.cleaning),
        ],
      );
    }
    return Text(AppLocalizations.of(context)!.none);
  }

  Future<bool> _onProgress(
    String fileName,
    int current,
    int total,
    int status,
  ) async {
    setState(() {
      _moveStatus = status;
      _total = total;
      _current = current;
      _fileName = fileName;
    });
    return _continueMove;
  }

  String _getTitle() {
    if (_moveStatus == Constant.moveToRecycleBinStatusCopy) {
      return AppLocalizations.of(context)!.moveToRecyclingBin;
    }
    if (_moveStatus == Constant.moveToRecycleBinStatusScan) {
      return AppLocalizations.of(context)!.statistics;
    }
    if (_moveStatus == Constant.moveToRecycleBinStatusDelete) {
      return AppLocalizations.of(context)!.cleanTitle;
    }
    return AppLocalizations.of(context)!.delete;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(width: 400, child: _getContent()),
      title: Text(_getTitle()),
      actions: [
        TextButton(
          onPressed: () {
            if (_moveStatus == Constant.moveToRecycleBinStatusReady) {
              Navigator.of(context).pop(false);
            } else {
              _continueMove = false;
            }
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        if (_moveStatus == Constant.moveToRecycleBinStatusReady)
          TextButton(
            onPressed: () async {
              var result = await GlobalDepend.moveToRecycleBin(
                widget.path,
                onProgress: _onProgress,
              );
              BuildContext finalContext = context;
              if (finalContext.mounted) {
                var tip = AppLocalizations.of(
                  finalContext,
                )!.moveToRecycleBinFail;
                if (result == Constant.moveToRecycleBinCancel) {
                  tip = AppLocalizations.of(
                    finalContext,
                  )!.moveToRecycleBinCancel;
                } else if (result == Constant.moveToRecycleBinSuccess) {
                  tip = AppLocalizations.of(
                    finalContext,
                  )!.moveToRecycleBinSuccess;
                }
                ScaffoldMessenger.of(
                  finalContext,
                ).showSnackBar(SnackBar(content: Text(tip)));
                Navigator.of(finalContext).pop(true);
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
      ],
    );
  }
}
