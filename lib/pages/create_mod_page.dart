import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/mod/mod.dart';
import 'package:sprintf/sprintf.dart';

import '../constant.dart';
import '../global_depend.dart';
import '../l10n/app_localizations.dart';
import 'edit_units_page.dart';

class CreateModPage extends StatefulWidget {
  const CreateModPage({super.key});

  @override
  State<CreateModPage> createState() => _CreateModPageState();
}

class _CreateModPageState extends State<CreateModPage> {
  late String _modPath;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final _minVersionController = TextEditingController();

  String? _titleErrorText;
  bool _rememberChoice = false;
  List<String> _chips = [];

  List<String> _availableVersions = [];
  String? _selectedVersion;

  @override
  void initState() {
    super.initState();
    _modPath = HiveHelper.get(HiveHelper.modPath);
    _tagsController.addListener(_updateChipsFromText);
    _titleController.addListener(_checkTitleExists);

    _availableVersions = CodeDataBase.getGameVersion()
        .where((v) => v.visible == true)
        .map((v) => v.versionName ?? '')
        .where((v) => v.isNotEmpty)
        .toList();

    if (_availableVersions.isNotEmpty) {
      _selectedVersion = _availableVersions.first;
      _minVersionController.text = _selectedVersion!;
    }
  }

  void _updateChipsFromText() {
    final raw = _tagsController.text;
    final tags = raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _chips = tags;
    });
  }

  void _removeChip(String tag) {
    setState(() {
      _chips.remove(tag);
      _tagsController.text = _chips.join(', ');
      _tagsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tagsController.text.length),
      );
    });
  }

  void _checkTitleExists() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() => _titleErrorText = null);
      return;
    }

    if (!GlobalDepend.isValidFileName(title)) {
      setState(
        () => _titleErrorText = AppLocalizations.of(
          context,
        )!.titleContainsIllegalCharacter,
      );
      return;
    }

    final modFolder = p.join(_modPath, GlobalDepend.getSecureFileName(title));
    final exists = await Directory(modFolder).exists();

    setState(() {
      _titleErrorText = exists
          ? sprintf(AppLocalizations.of(context)!.modRepeatedlyPrompts, [title])
          : null;
    });
  }

  void _showOpenWorkspaceAfterCreateModDialog(String path) async {
    bool? result = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.modCreatedSuccessfullyTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.whetherOpenWorkspaceImmediately,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberChoice,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _rememberChoice = value);
                    },
                  ),
                  Text(AppLocalizations.of(context)!.rememberMyChoice),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_rememberChoice) {
                  HiveHelper.put(
                    HiveHelper.openWorkspaceAfterCreateMod,
                    Constant.openWorkSpaceNever,
                  );
                } else {
                  HiveHelper.put(
                    HiveHelper.openWorkspaceAfterCreateMod,
                    Constant.openWorkSpaceAsk,
                  );
                }
                Navigator.pop(context, true);
              },
              child: Text(AppLocalizations.of(context)!.later),
            ),
            TextButton(
              onPressed: () {
                if (_rememberChoice) {
                  HiveHelper.put(
                    HiveHelper.openWorkspaceAfterCreateMod,
                    Constant.openWorkSpaceAlways,
                  );
                } else {
                  HiveHelper.put(
                    HiveHelper.openWorkspaceAfterCreateMod,
                    Constant.openWorkSpaceAsk,
                  );
                }
                Navigator.pop(context, false);
                _openWorkSpace(path);
              },
              child: Text(AppLocalizations.of(context)!.openWorkSpace),
            ),
          ],
        ),
      ),
    );
    var finalContext = context;
    if (finalContext.mounted && result == true) {
      Navigator.of(finalContext).pop();
    }
  }

  void _openWorkSpace(String path) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EditUnitsPage(mod: Mod(path))),
    );
  }

  Future<void> _createMod() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleErrorText = AppLocalizations.of(context)!.titleCannotBeEmpty;
      });
      return;
    }

    final desc = _descController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final minVersion = _minVersionController.text.trim();

    final buffer = StringBuffer('[mod]\n');
    buffer.writeln('title:$title');
    if (desc.isNotEmpty) buffer.writeln('description:$desc');
    if (tags.isNotEmpty) buffer.writeln('tags:${tags.join(',')}');
    if (minVersion.isNotEmpty) buffer.writeln('minVersion:$minVersion');
    try {
      final FileSystemOperator fileSystemOperator =
          GlobalDepend.getFileSystemOperator();
      var path = fileSystemOperator.join(
        _modPath,
        GlobalDepend.getSecureFileName(title),
      );
      await fileSystemOperator.mkdir(
        _modPath,
        GlobalDepend.getSecureFileName(title),
      );
      await fileSystemOperator.writeFile(
        path,
        Constant.modInfoFileName,
        buffer.toString(),
      );
      if (!mounted) return;
      final int openWorkspaceAfterCreateMod = HiveHelper.get(
        HiveHelper.openWorkspaceAfterCreateMod,
        defaultValue: Constant.openWorkSpaceAsk,
      );
      if (openWorkspaceAfterCreateMod == Constant.openWorkSpaceAsk) {
        _showOpenWorkspaceAfterCreateModDialog(path);
        return;
      }
      if (openWorkspaceAfterCreateMod == Constant.openWorkSpaceAlways) {
        //直接打开工作区
        _openWorkSpace(path);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.modCreatedSuccessfully),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.modCreatedFailed),
          content: Text(
            sprintf(AppLocalizations.of(context)!.modCreatedFailedMessage, [
              error.toString(),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _minVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.createMod)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title,
                border: const OutlineInputBorder(),
                errorText: _titleErrorText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.tags,
                border: OutlineInputBorder(),
                helperText: AppLocalizations.of(context)!.tagsTip,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              children: _chips.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeChip(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return _availableVersions;
                }
                return _availableVersions.where((String option) {
                  return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              initialValue: TextEditingValue(text: _minVersionController.text),
              onSelected: (String selection) {
                _minVersionController.text = selection;
                setState(() {
                  _selectedVersion = selection;
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    controller.text = _minVersionController.text;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );

                    controller.addListener(() {
                      _minVersionController.text = controller.text;
                    });

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.minVersion,
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: const OutlineInputBorder(),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  (_titleController.text.trim().isNotEmpty &&
                      _titleErrorText == null)
                  ? _createMod
                  : null,
              child: Text(AppLocalizations.of(context)!.createMod),
            ),
          ],
        ),
      ),
    );
  }
}
