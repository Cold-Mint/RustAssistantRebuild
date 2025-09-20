import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:sprintf/sprintf.dart';

import 'constant.dart';
import 'l10n/app_localizations.dart';

class UriPermissionsDialog extends StatefulWidget {
  const UriPermissionsDialog({super.key});

  @override
  State<UriPermissionsDialog> createState() => _UriPermissionsDialogState();
}

class _UriPermissionsDialogState extends State<UriPermissionsDialog> {
  static const platform = MethodChannel(Constant.androidChannel);

  List<Map<String, dynamic>> _permissions = [];
  Set<String> _selectedUris = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        Constant.getPersistedUriPermissions,
      );
      setState(() {
        _permissions = result
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _permissions = [];
        _loading = false;
      });
      var finalContext = context;
      if (finalContext.mounted) {
        ScaffoldMessenger.of(finalContext).showSnackBar(
          SnackBar(content: Text('Failed to load permissions: ${e.message}')),
        );
      }
    }
  }

  void _onUriSelected(bool? selected, String uri) {
    setState(() {
      if (selected == true) {
        _selectedUris.add(uri);
      } else {
        _selectedUris.remove(uri);
      }
    });
  }

  Future<void> _revokeSelected() async {
    for (var uri in _selectedUris) {
      try {
        await platform.invokeMethod(Constant.releasePersistableUriPermission, {
          'uri': uri,
          'flags': 3,
          // FLAG_GRANT_READ_URI_PERMISSION | FLAG_GRANT_WRITE_URI_PERMISSION = 1 | 2 = 3
        });
      } catch (e) {
        // 可以打印或显示错误信息
        debugPrint('Failed to revoke $uri: $e');
      }
    }
    var finalContext = context;
    if (finalContext.mounted) {
      Navigator.of(finalContext).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.revokeGrantedAccessPermissionSAFDirectory,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _permissions.isEmpty
            ? Text(AppLocalizations.of(context)!.noSAFDirectoryPermissions)
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final item = _permissions[index];
                  final uri = item['uri'] as String;
                  final selected = _selectedUris.contains(uri);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(uri),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: selected,
                    onChanged: (bool? value) => _onUriSelected(value, uri),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // 取消
          child: Text(
            _permissions.isEmpty
                ? AppLocalizations.of(context)!.confirm
                : AppLocalizations.of(context)!.cancel,
          ),
        ),
        if (_permissions.isNotEmpty)
          TextButton(
            onPressed:
                _selectedUris.length == _permissions.length ||
                    _permissions.isEmpty
                ? null
                : () {
                    setState(() {
                      _selectedUris = _permissions
                          .map<String>((item) => item['uri'] as String)
                          .toSet();
                    });
                  },
            child: Text(AppLocalizations.of(context)!.selectAll),
          ),

        if (_permissions.isNotEmpty)
          TextButton(
            onPressed: _selectedUris.isNotEmpty ? _revokeSelected : null,
            child: Text(
              sprintf(AppLocalizations.of(context)!.revoke, [
                _selectedUris.length,
              ]),
            ),
          ),
      ],
    );
  }
}
