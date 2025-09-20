import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/code_info.dart';
import 'package:rust_assistant/global_depend.dart';

import 'databeans/code.dart';
import 'databeans/key_value.dart';
import 'l10n/app_localizations.dart';
import 'mod/ini_reader.dart';

class EditSequenceDialog extends StatefulWidget {
  const EditSequenceDialog({
    super.key,
    required this.iniReader,
    required this.sectionName,
    required this.save,
  });

  final IniReader iniReader;
  final String sectionName;
  final Function(String) save;

  @override
  State<StatefulWidget> createState() {
    return _EditSequenceDialogStatus();
  }
}

class _EditSequenceDialogStatus extends State<EditSequenceDialog> {
  late List<KeyValue> keyValueList;
  bool _translationMode = true;

  @override
  void initState() {
    super.initState();
    // 初始化数据，只存 KeyValue 列表
    keyValueList = widget.iniReader.getKeyValueInSection(
      widget.sectionName,
      fullSectionName: false,
      containsNotes: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    String sectionPrefix = GlobalDepend.getSectionPrefix(widget.sectionName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.editingSequence,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(AppLocalizations.of(context)!.translationMode),
                const Spacer(),
                Switch(
                  value: _translationMode,
                  onChanged: (value) {
                    setState(() {
                      _translationMode = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: keyValueList.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = keyValueList.removeAt(oldIndex);
                    keyValueList.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final kv = keyValueList[index];
                  return SimpleDataInterpreter(
                    key: ValueKey('${kv.key}:${kv.value}:$_translationMode'),
                    keyValue: kv,
                    sectionPrefix: sectionPrefix,
                    translationMode: _translationMode,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    StringBuffer stringBuffer = StringBuffer();
                    for (var value in keyValueList) {
                      if (stringBuffer.length > 0) {
                        stringBuffer.write('\n');
                      }
                      stringBuffer.write(value.getLineData());
                    }
                    widget.save.call(stringBuffer.toString());
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleDataInterpreter extends StatefulWidget {
  const SimpleDataInterpreter({
    super.key,
    required this.keyValue,
    required this.translationMode,
    required this.sectionPrefix,
  });

  final KeyValue keyValue;
  final bool translationMode;
  final String sectionPrefix;

  @override
  State<StatefulWidget> createState() {
    return _SimpleDataInterpreterState();
  }
}

class _SimpleDataInterpreterState extends State<SimpleDataInterpreter> {
  Code? code;
  CodeInfo? codeInfo;

  @override
  void initState() {
    super.initState();
    if (!widget.keyValue.isNote) {
      code = CodeDataBase.getCode(widget.keyValue.key, widget.sectionPrefix);
      codeInfo = CodeDataBase.getCodeInfo(
        widget.keyValue.key,
        widget.sectionPrefix,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果是注释，直接显示内容
    if (widget.keyValue.isNote) {
      return ListTile(
        key: ValueKey(widget.keyValue),
        title: const Text("#"),
        subtitle: Text(widget.keyValue.value?.toString() ?? ''),
        trailing: const Icon(Icons.drag_handle_outlined),
      );
    }

    // 根据 translationMode 显示不同的文本
    final titleText = widget.translationMode
        ? (codeInfo?.translate ?? widget.keyValue.key)
        : widget.keyValue.key;

    return ListTile(
      key: ValueKey(widget.keyValue),
      title: Text(titleText),
      subtitle: Text(widget.keyValue.value?.toString() ?? ''),
      trailing: const Icon(Icons.drag_handle_outlined),
    );
  }
}
