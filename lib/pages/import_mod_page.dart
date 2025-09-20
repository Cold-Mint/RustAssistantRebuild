import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/mod/mod.dart';

import '../global_depend.dart';
import '../l10n/app_localizations.dart';

class ImportModPage extends StatefulWidget {
  final List<Mod> modList;

  const ImportModPage({super.key, required this.modList});

  @override
  State<StatefulWidget> createState() {
    return _ImportModPageStatus();
  }
}

enum ImportStatus { ready, importing, done, error }

class ImportingMod {
  final Mod mod;
  ImportStatus status;
  String? errorInfo;

  ImportingMod(this.mod, {this.status = ImportStatus.ready});
}

class _ImportModPageStatus extends State<ImportModPage> {
  late List<ImportingMod> _modList;
  int _importCode = Constant.importCodeRead;

  @override
  void initState() {
    super.initState();
    _modList = widget.modList.map((m) => ImportingMod(m)).toList();
  }

  String getSubTitle(ImportingMod importMod) {
    if (importMod.errorInfo != null) {
      return importMod.errorInfo!;
    }
    if (importMod.mod.modDescription == null) {
      return AppLocalizations.of(context)!.none;
    }
    if (importMod.mod.modDescription!.isEmpty) {
      return AppLocalizations.of(context)!.none;
    }
    return importMod.mod.modDescription!;
  }

  Widget getCoreWidget(BuildContext context) {
    if (_modList.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.none,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: _modList.length,
      itemBuilder: (context, index) {
        final ImportingMod importingMod = _modList[index];
        return Padding(
          padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
          child: Card.filled(
            child: ListTile(
              leading: GlobalDepend.getIcon(context, importingMod.mod),
              title: Text(
                importingMod.mod.modName ?? AppLocalizations.of(context)!.none,
              ),
              subtitle: Text(
                getSubTitle(importingMod),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Builder(
                builder: (context) {
                  if (_importCode == Constant.importCodeRead) {
                    return IconButton(
                      tooltip: AppLocalizations.of(context)!.remove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _modList.remove(importingMod);
                        });
                      },
                    );
                  }
                  if (importingMod.status == ImportStatus.ready) {
                    return SizedBox();
                  } else if (importingMod.status == ImportStatus.importing) {
                    return const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  } else if (importingMod.status == ImportStatus.done) {
                    return Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  } else {
                    return Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.importMod)),
      body: Column(
        children: [
          Expanded(child: getCoreWidget(context)),
          if (_modList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: _importCode == Constant.importCodeLoading
                    ? FilledButton(
                        onPressed: null,
                        child: Text(AppLocalizations.of(context)!.importMod),
                      )
                    : _importCode == Constant.importCodeCompleted
                    ? FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.finish),
                      )
                    : FilledButton(
                        onPressed: _importMod,
                        child: Text(AppLocalizations.of(context)!.importMod),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  void _importMod() async {
    setState(() {
      _importCode = Constant.importCodeLoading;
    });
    final FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    var modFolder = HiveHelper.get(HiveHelper.modPath);

    for (var importingMod in _modList) {
      setState(() {
        importingMod.status = ImportStatus.importing;
      });

      try {
        final mod = importingMod.mod;
        final srcPath = mod.path;
        if (await fileSystemOperator.isDir(srcPath)) {
          var fileName = GlobalDepend.getSecureFileName(
            await fileSystemOperator.name(mod.path),
          );
          var newModPath = fileSystemOperator.join(modFolder, fileName);
          if (await fileSystemOperator.exist(newModPath)) {
            setState(() {
              importingMod.status = ImportStatus.error;
              importingMod.errorInfo = AppLocalizations.of(
                context,
              )!.modAlreadyExists;
            });
            continue;
          }
          await fileSystemOperator.mkdir(modFolder, fileName);
          await fileSystemOperator.list(srcPath, recursive: true, (str) async {
            var isDir = await fileSystemOperator.isDir(str);
            final destPath = fileSystemOperator.join(
              newModPath,
              await fileSystemOperator.relative(str, srcPath),
            );
            if (isDir) {
              var destDir = Directory(destPath);
              if (!await destDir.exists()) {
                await destDir.create(recursive: true);
              }
            } else {
              await fileSystemOperator.copyToPath(str, destPath);
            }
            return false;
          });
        } else {
          var newModPath = fileSystemOperator.join(
            modFolder,
            await fileSystemOperator.name(srcPath),
          );
          if (await fileSystemOperator.exist(newModPath)) {
            setState(() {
              importingMod.status = ImportStatus.error;
              importingMod.errorInfo = AppLocalizations.of(
                context,
              )!.modAlreadyExists;
            });
            continue;
          }
          await fileSystemOperator.copyToPath(srcPath, newModPath);
        }
        if (Platform.isAndroid) {
          MethodChannel androidChannel = MethodChannel(Constant.androidChannel);
          await androidChannel.invokeMethod(Constant.deleteUnintroducedModPath);
        }
        setState(() {
          importingMod.status = ImportStatus.done;
        });
      } catch (e) {
        debugPrint("Import error: $e");
        setState(() {
          importingMod.status = ImportStatus.error;
          importingMod.errorInfo = e.toString();
        });
      }
    }

    setState(() {
      _importCode = Constant.importCodeCompleted;
    });
  }
}
