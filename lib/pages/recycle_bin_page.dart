import 'package:flutter/material.dart';
import 'package:rust_assistant/clear_recycle_bin_dialog.dart';
import 'package:rust_assistant/databeans/recycle_bin_item.dart';
import 'package:rust_assistant/forever_delete_dialog.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';
import 'package:rust_assistant/restore_dialog.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RecycleBinPageStatus();
  }
}

class _RecycleBinPageStatus extends State<RecycleBinPage> {
  final List<RecycleBinItem> _recycleBinList = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    _recycleBinList.addAll(GlobalDepend.getRecycleBinList());
  }

  Widget getBody() {
    if (_recycleBinList.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noFilesFolders,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: _recycleBinList.length,
      itemBuilder: (context, index) {
        return Card.filled(
          child: ListTile(
            title: Text(
              _recycleBinList[index].name ?? AppLocalizations.of(context)!.none,
            ),
            subtitle: Text(
              _recycleBinList[index].path ?? AppLocalizations.of(context)!.none,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: AppLocalizations.of(context)!.restore,
                  onPressed: () {
                    var item = _recycleBinList[index];
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return RestoreDialog(
                          recycleBinItem: item,
                          onRestore: (listItem) {
                            setState(() {
                              _recycleBinList.remove(item);
                            });
                          },
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.restore_from_trash_outlined),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.delete,
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () {
                    var item = _recycleBinList[index];
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return ForeverDeleteDialog(
                          recycleBinItem: item,
                          onDelete: (listItem) {
                            setState(() {
                              _recycleBinList.remove(item);
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recycleBin),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_sharp),
            tooltip: AppLocalizations.of(context)!.clearRecycleBin,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return ClearRecycleBinDialog(
                    onClear: () {
                      setState(() {
                        _recycleBinList.clear();
                      });
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: getBody(),
    );
  }
}
