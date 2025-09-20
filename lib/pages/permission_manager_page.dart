import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant.dart';
import '../l10n/app_localizations.dart';

class PermissionManagerPage extends StatefulWidget {
  final Function(bool)? onCompleted;
  final bool embeddedPattern;

  const PermissionManagerPage({
    super.key,
    this.onCompleted,
    required this.embeddedPattern,
  });

  @override
  State<StatefulWidget> createState() {
    return _PermissionManagerPageStatus();
  }
}

class _PermissionManagerPageStatus extends State<PermissionManagerPage> {
  final MethodChannel _androidMethodChannel = MethodChannel(
    Constant.androidChannel,
  );
  bool _hasManageExternalStoragePermission = false;

  @override
  void initState() {
    super.initState();
    _loadHasManageExternalStoragePermission();
  }

  void _loadHasManageExternalStoragePermission() async {
    final bool hasPermission = await _checkPermissions();
    setState(() {
      _hasManageExternalStoragePermission = hasPermission;
    });
    widget.onCompleted?.call(hasPermission);
  }

  Future<bool> _requestStoragePermissions() async {
    final result = await _androidMethodChannel.invokeMethod<bool>(
      Constant.requestPermissions,
    );
    return result ?? false;
  }

  Future<bool> _checkPermissions() async {
    final result = await _androidMethodChannel
        .invokeMethod<Map<dynamic, dynamic>>(Constant.checkPermissions);
    if (result == null) return false;
    return result['MANAGE_EXTERNAL_STORAGE'] == true;
  }

  Widget _useFileManagerWidgetList() {
    return Column(
      children: [
        if (!_hasManageExternalStoragePermission)
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final bool result = await _requestStoragePermissions();
                      setState(() {
                        _hasManageExternalStoragePermission = result;
                      });
                      widget.onCompleted?.call(result);
                    },
                    child: Text(AppLocalizations.of(context)!.authorization),
                  ),
                ),
              ],
            ),
          ),
        if (_hasManageExternalStoragePermission)
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.allFileAccessPermissionSettings,
            ),
            onTap: () {
              _androidMethodChannel.invokeMethod(
                Constant.openStoragePermissionSetting,
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedPattern) {
      return _useFileManagerWidgetList();
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppLocalizations.of(context)!.descriptionOfPermissionGranting,
            ),
          ),
          FilledButton(
            onPressed: _hasManageExternalStoragePermission
                ? null
                : () async {
                    final bool result = await _requestStoragePermissions();
                    setState(() {
                      _hasManageExternalStoragePermission = result;
                    });
                    widget.onCompleted?.call(result);
                  },
            child: Text(AppLocalizations.of(context)!.authorization),
          ),
        ],
      );
    }
  }
}
