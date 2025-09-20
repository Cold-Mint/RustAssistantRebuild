import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:sprintf/sprintf.dart';

import 'databeans/unit_template.dart';
import 'global_depend.dart';
import 'l10n/app_localizations.dart';

class CreateFileOfFolderDialog extends StatefulWidget {
  const CreateFileOfFolderDialog({
    super.key,
    required this.folder,
    required this.onCreate,
  });

  final String folder;

  //路径，是否为文件夹，用户输入的文件名，是否需要填入默认数据
  final Function(String, bool, String, bool, Templates?, String) onCreate;

  @override
  State<StatefulWidget> createState() {
    return _CreateFileOfFolderStatus();
  }
}

class _CreateFileOfFolderStatus extends State<CreateFileOfFolderDialog> {
  bool _isLegal = false;
  bool _asFolder = false;
  bool _createdFromUnitTemplate = true;
  String? _errorText;
  String _inputText = "";
  final FileSystemOperator _fileSystemOperator =
      GlobalDepend.getFileSystemOperator();

  // 文件类型列表，用于自动完成
  final List<String> _fileExtensions = ['ini', 'template', 'txt'];
  final List<Templates> _unitsTemplate = List.empty(growable: true);
  Templates? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    var unitsTemplate = CodeDataBase.getUnitsTemplate();
    if (unitsTemplate != null) {
      var templates = unitsTemplate.templates;
      if (templates != null && templates.isNotEmpty) {
        for (var value in templates) {
          _selectedTemplate ??= value;
          _unitsTemplate.add(value);
        }
      }
    }
  }

  List<String> _getSuggestions(String text) {
    if (_asFolder || text.isEmpty) {
      return [];
    }

    List<String> result = List.empty(growable: true);
    var indexOf = text.lastIndexOf('.');
    String format = "";
    if (indexOf > -1) {
      //有符号
      format = text.substring(indexOf + 1);
    }
    if (format.isEmpty) {
      for (var value in _fileExtensions) {
        if (indexOf > -1) {
          result.add("$text$value");
        } else {
          result.add("$text.$value");
        }
      }
    } else {
      for (var value in _fileExtensions) {
        if (value != format && value.startsWith(format)) {
          result.add("${text.substring(0, indexOf)}.$value");
        }
      }
    }

    return result;
  }

  // 检查文件是否存在
  Future<void> _checkFileExistence(String fileName) async {
    if (fileName.isEmpty) {
      setState(() {
        _errorText = null;
        _isLegal = false;
      });
      return;
    }

    final filePath = _fileSystemOperator.join(
      widget.folder,
      GlobalDepend.getSecureFileName(fileName),
    );

    if (await _fileSystemOperator.exist(filePath)) {
      setState(() {
        _errorText = sprintf(
          AppLocalizations.of(context)!.fileRepeatedlyPrompts,
          [fileName],
        );
        _isLegal = false;
      });
    } else if (GlobalDepend.isValidFileName(fileName)) {
      setState(() {
        _errorText = null;
        _isLegal = true;
      });
    } else {
      setState(() {
        _errorText = AppLocalizations.of(
          context,
        )!.titleContainsIllegalCharacter;
        _isLegal = false;
      });
    }
  }

  void _onTemplateSelected(Templates? newValue) {
    setState(() {
      _selectedTemplate = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.create),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              displayStringForOption: (option) => option,
              optionsBuilder: (TextEditingValue textEditingValue) {
                return _getSuggestions(textEditingValue.text);
              },
              onSelected: (selected) {
                setState(() {
                  _inputText = selected;
                });
                _checkFileExistence(selected);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (text) {
                        setState(() {
                          _inputText = text;
                        });
                        _checkFileExistence(text);
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(
                          context,
                        )!.fileNameOrFolderName,
                        errorText: _errorText,
                      ),
                    );
                  },
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.createdAsFolder),
                ),
                Switch(
                  value: _asFolder,
                  onChanged: (b) {
                    setState(() {
                      _asFolder = b;
                      _checkFileExistence(_inputText);
                    });
                  },
                ),
              ],
            ),
            if (!_asFolder) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.createdFromUnitTemplate,
                    ),
                  ),
                  Switch(
                    value: _createdFromUnitTemplate,
                    onChanged: (b) {
                      setState(() {
                        _createdFromUnitTemplate = b;
                      });
                    },
                  ),
                ],
              ),
            ],

            // 只有当有模板时才显示下拉框
            if (!_asFolder &&
                _createdFromUnitTemplate &&
                _unitsTemplate.isNotEmpty &&
                _inputText.toString().toLowerCase() !=
                    Constant.modInfoFileName &&
                _inputText.toString().toLowerCase() !=
                    Constant.allUnitsTemplate) ...[
              SizedBox(height: 8),
              DropdownButtonFormField<Templates>(
                initialValue: _selectedTemplate,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.unitsTemplate,
                  border: const OutlineInputBorder(),
                ),
                items: _unitsTemplate
                    .map<DropdownMenuItem<Templates>>(
                      (Templates t) => DropdownMenuItem<Templates>(
                        value: t,
                        child: Text(t.name ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: _onTemplateSelected,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 关闭对话框
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _isLegal
              ? () {
                  var secureFileName = GlobalDepend.getSecureFileName(
                    _inputText,
                  );
                  var joinedPath = GlobalDepend.getFileSystemOperator().join(
                    widget.folder,
                    secureFileName,
                  );
                  widget.onCreate(
                    joinedPath,
                    _asFolder,
                    secureFileName,
                    _createdFromUnitTemplate,
                    _selectedTemplate,
                    _inputText,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: Text(AppLocalizations.of(context)!.create),
        ),
      ],
    );
  }
}
