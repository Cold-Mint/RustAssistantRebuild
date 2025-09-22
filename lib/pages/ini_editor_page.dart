import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/dataSources/code_data_source.dart';
import 'package:rust_assistant/dataSources/section_data_source.dart';
import 'package:rust_assistant/databeans/code.dart';
import 'package:rust_assistant/databeans/key_value.dart';
import 'package:rust_assistant/databeans/resource_ref.dart';
import 'package:rust_assistant/databeans/section_info.dart';
import 'package:rust_assistant/edit_sequence_dialog.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/interpreters/color_interpreter.dart';
import 'package:rust_assistant/interpreters/enum_interprete.dart';
import 'package:rust_assistant/interpreters/file_data_interpreter.dart';
import 'package:rust_assistant/interpreters/tag_interprete.dart';
import 'package:rust_assistant/interpreters/unit_interpreter.dart';
import 'package:rust_assistant/mod/ini_writer.dart';
import 'package:rust_assistant/mod/ini_reader.dart';
import 'package:rust_assistant/search_multiple_selection_dialog.dart';

import '../databeans/code_info.dart';
import '../interpreters/bool_data_interpreter.dart';
import '../interpreters/file_list_interpreter.dart';
import '../interpreters/data_interpreter.dart';
import '../interpreters/float_data_interpreter.dart';
import '../interpreters/float_or_time_data_interpreter.dart';
import '../interpreters/int_data_interpreter.dart';
import '../interpreters/int_or_price_data_interpreter.dart';
import '../interpreters/logic_boolean_data_interpreter.dart';
import '../interpreters/multilingual_text_interpreter.dart';
import '../interpreters/note_data_interpreter.dart';
import '../interpreters/section_interpreter.dart';
import '../interpreters/string_data_interpreter.dart';
import '../l10n/app_localizations.dart';

class IniEditorPage extends StatefulWidget {
  final bool displayLineNumber;
  final bool displayOperationOptions;
  final Function(String) onRequestOpenFile;
  final Function onRequestChangeLeftWidget;
  final List<String> tagList;

  const IniEditorPage({
    super.key,
    required this.sourceFilePath,
    this.fileData,
    this.onDataChange,
    required this.globalResource,
    required this.displayLineNumber,
    required this.displayOperationOptions,
    this.onMaxLineNumberChange,
    required this.onRequestOpenDrawer,
    required this.onRequestChangeLeftWidget,
    required this.onRequestOpenFile,
    required this.modPath,
    required this.tagList,
  });

  final List<ResourceRef> globalResource;
  final String sourceFilePath;
  final String modPath;

  //文件内容
  final String? fileData;

  //当文件内容被改变时
  final Function(String)? onDataChange;

  final Function(int)? onMaxLineNumberChange;
  final Function onRequestOpenDrawer;

  @override
  State<StatefulWidget> createState() {
    return _IniEditorPageStatus();
  }
}

class _IniEditorPageStatus extends State<IniEditorPage>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _errorInfo;
  IniReader? _iniReader;
  final List<DataInterpreter> _dataInterpreters = List.empty(growable: true);
  final Map<DataInterpreter, String> _dataInterpretersValues = {};
  int _mode = _modeVisual;
  static final int _modeVisual = 1;
  static final int _modeEditor = 2;
  final TextEditingController _textEditingController = TextEditingController();
  int _maxLineNumber = 0;
  final FileSystemOperator _fileSystemOperator =
      GlobalDepend.getFileSystemOperator();

  List<ResourceRef> getLocalResource() {
    final List<ResourceRef> returnList = [];
    final List<String> allSection = _iniReader!.getAllSection();
    if (allSection.isEmpty) {
      return returnList;
    }
    for (var section in allSection) {
      var name = GlobalDepend.getSectionPrefix(section).toLowerCase();
      if (name == "resource") {
        var last = GlobalDepend.getSectionSuffix(section);
        var language = GlobalDepend.getLanguage(context);
        String? displayName = _iniReader!
            .getKeyValueFromSection(section, "displayName_$language")
            ?.value;
        displayName ??= _iniReader!
            .getKeyValueFromSection(section, "displayName")
            ?.value;
        if (last.isNotEmpty) {
          returnList.add(
            ResourceRef(
              name: last,
              path: widget.sourceFilePath,
              globalResource: false,
              displayName: displayName,
            ),
          );
        }
      }
    }
    return returnList;
  }

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _loadFile() async {
    setState(() {
      _loading = true;
      _errorInfo = null;
    });
    if (widget.fileData == null) {
      if (!await _fileSystemOperator.exist(widget.sourceFilePath)) {
        setState(() {
          _loading = false;
          _errorInfo = AppLocalizations.of(context)!.fileNotExist;
        });
        return;
      }

      if (await _fileSystemOperator.isDir(widget.sourceFilePath)) {
        setState(() {
          _loading = false;
          _errorInfo = AppLocalizations.of(context)!.dataCannotLoadedFromFolder;
        });
        return;
      }
      final String data =
          await _fileSystemOperator.readAsString(widget.sourceFilePath) ?? "";
      _iniReader = IniReader(data, containsNotes: true);
      if (!mounted) {
        return;
      }
      _textEditingController.text = data;
    } else {
      if (!mounted) {
        return;
      }
      _iniReader = IniReader(widget.fileData!, containsNotes: true);
      _textEditingController.text = widget.fileData!;
    }
    setState(() {
      _loading = false;
      _errorInfo = null;
    });
  }

  String toIniData() {
    StringBuffer stringBuffer = StringBuffer();
    for (var dataInterpreter in _dataInterpreters) {
      if (!_dataInterpretersValues.containsKey(dataInterpreter)) {
        continue;
      }
      stringBuffer.write(_dataInterpretersValues[dataInterpreter]);
      stringBuffer.write("\n");
    }
    return stringBuffer.toString();
  }

  DataInterpreter getCodeView(
    KeyValue keyValue,
    int lineNumber,
    Code codeData,
    CodeInfo? codeInfo,
  ) {
    var interpreterData = codeData.interpreter;
    if (interpreterData == null) {
      return getDefaultView(lineNumber, keyValue, codeData, codeInfo);
    }

    var interpreter = interpreterData;
    var symbolPosition = interpreter.indexOf('=');
    String? arguments;
    if (symbolPosition > -1) {
      arguments = interpreter.substring(symbolPosition + 1);
      interpreter = interpreter.substring(0, symbolPosition);
    }
    if (interpreter == "string") {
      return StringDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "color") {
      return ColorInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "int") {
      return IntDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "float") {
      return FloatDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "intOrPrice") {
      return IntORPriceDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        globalResource: widget.globalResource,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        onRequestOpenFile: widget.onRequestOpenFile,
        getLocalResource: getLocalResource,
      );
    } else if (interpreter == "floatORTime") {
      return FloatORTimeDataInterpreter(
        lineNumber: lineNumber,
        lockTime: false,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "time") {
      return FloatORTimeDataInterpreter(
        lineNumber: lineNumber,
        lockTime: true,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "enum") {
      return EnumInterprete(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        arguments: arguments,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "tagsWithoutAddDialog") {
      return TagInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        tagList: widget.tagList,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        enableAddDialog: false,
      );
    } else if (interpreter == "tags") {
      return TagInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        tagList: widget.tagList,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        enableAddDialog: true,
      );
    } else if (interpreter == "bool") {
      return BoolDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "logicBoolean") {
      return LogicBooleanDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "multilingual") {
      return MultilingualTextInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
      );
    } else if (interpreter == "fileList") {
      return FileListInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        onRequestOpenFile: widget.onRequestOpenFile,
        sourceFilePath: widget.sourceFilePath,
        selectFileType: _argumentsToFileType(arguments),
        modPath: widget.modPath,
      );
    } else if (interpreter == "fileSupportAuto") {
      return FileDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        sourceFilePath: widget.sourceFilePath,
        modPath: widget.modPath,
        selectFileType: _argumentsToFileType(arguments),
        supportAuto: true,
      );
    } else if (interpreter == "file") {
      return FileDataInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        sourceFilePath: widget.sourceFilePath,
        modPath: widget.modPath,
        supportAuto: false,
        selectFileType: _argumentsToFileType(arguments),
      );
    } else if (interpreter == "unit") {
      return UnitInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        multiple: false,
      );
    } else if (interpreter == "unitList") {
      return UnitInterpreter(
        lineNumber: lineNumber,
        keyValue: keyValue,
        codeData: codeData,
        codeInfo: codeInfo,
        onLineDataChange: onLineDataChange,
        displayLineNumber: widget.displayLineNumber,
        displayOperationOptions: widget.displayOperationOptions,
        multiple: true,
      );
    }
    return getDefaultView(lineNumber, keyValue, codeData, codeInfo);
  }

  int _argumentsToFileType(String? arguments) {
    if (arguments == null) {
      return FileTypeChecker.FileTypeAll;
    }
    if (arguments == "text") {
      return FileTypeChecker.FileTypeText;
    }
    if (arguments == "image") {
      return FileTypeChecker.FileTypeImage;
    }
    if (arguments == "audio") {
      return FileTypeChecker.FileTypeAudio;
    }
    return FileTypeChecker.FileTypeAll;
  }

  void onLineDataChange(DataInterpreter dataInterpreter, String lineData) {
    _dataInterpretersValues[dataInterpreter] = lineData;
    var newIniData = toIniData();
    _textEditingController.text = newIniData;
    widget.onDataChange?.call(newIniData);
    _iniReader = IniReader(newIniData, containsNotes: true);
  }

  void editSequenceCallBack(String key) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return EditSequenceDialog(
          iniReader: _iniReader!,
          sectionName: key,
          save: (string) {
            var newIniData = IniWriter.writeSection(
              original: _iniReader!.content,
              sectionName: "[$key]",
              content: string,
            );
            _textEditingController.text = newIniData;
            widget.onDataChange?.call(newIniData);
            _iniReader = IniReader(newIniData, containsNotes: true);
          },
        );
      },
    );
  }

  void deletSectionCallBack(String fullSectionName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.delete),
          content: Text(
            AppLocalizations.of(context)!.removeAllCodeWithInSection,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                var newIniData = IniWriter.removeSection(
                  _iniReader!.content,
                  fullSectionName,
                );
                _textEditingController.text = newIniData;
                widget.onDataChange?.call(newIniData);
                _iniReader = IniReader(newIniData, containsNotes: true);
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  void addCodeOrNote(int index, String key) {
    final CodeDataSource codeDataSource = CodeDataSource(
      AppLocalizations.of(context)!.addCodeTitle,
      AppLocalizations.of(context)!.searchTitleOrDescription,
      AppLocalizations.of(context)!.addCodeTip,
    );
    //代码到其出现的次数（只记录允许重复的）
    Map<String, int> codeToCount = {};
    while (true) {
      var nextIndex = index++;
      if (nextIndex >= _dataInterpreters.length) {
        break;
      }
      var dataInterpreter = _dataInterpreters[nextIndex];
      var codeInfo = dataInterpreter.codeInfo;
      if (codeInfo == null) {
        continue;
      }
      var code = dataInterpreter.codeData;
      if (code == null) {
        continue;
      }
      if (code.allowRepetition == true) {
        var code = codeInfo.code;
        if (code != null) {
          if (codeToCount.containsKey(code)) {
            codeToCount[code] = codeToCount[code]! + 1;
          } else {
            codeToCount[code] = 1;
          }
        }
      }
      codeDataSource.existedList.add(MixedCode(codeInfo, code));
    }
    var codeInfoList = CodeDataBase.getCodeInfoInSection(
      GlobalDepend.getSectionPrefix(key),
    );
    for (var codeInfo in codeInfoList) {
      var code = codeInfo.code;
      if (code == null) {
        continue;
      }
      var codeObj = CodeDataBase.getCodeObjectByCode(code);
      if (codeObj == null) {
        continue;
      }
      codeDataSource.allList.add(MixedCode(codeInfo, codeObj));
    }
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SearchMultipleSelectionDialog(
          onSelected: (list) {
            final List<MixedCode> mixedCodeList = List.empty(growable: true);
            for (var value in list) {
              if (value is MixedCode) {
                mixedCodeList.add(value);
              }
            }
            var appendData = StringBuffer();
            CodeDataBase.parseMixedCodeList(
              mixedCodeList,
              onParsed: (code, codeInfo) {
                if (code.defaultKey == null || code.defaultValue == null) {
                  return;
                }
                appendData.write('\n');
                if (code.allowRepetition == true &&
                    code.defaultKey!.contains("{x}")) {
                  appendData.write(
                    code.defaultKey!.replaceAll(
                      "{x}",
                      (codeToCount[code.code] ?? 0).toString(),
                    ),
                  );
                } else {
                  appendData.write(code.defaultKey);
                }
                appendData.write(':');
                appendData.write(' ');
                appendData.write(code.defaultValue);
              },
            );
            if (appendData.isNotEmpty) {
              var content = _iniReader?.content;
              if (content == null) {
                return;
              }
              final String fullSection = "[$key]";
              var fullSectionIndex = content.indexOf(fullSection);
              if (fullSectionIndex > -1) {
                //有位置
                var insertionPosition = fullSectionIndex + fullSection.length;
                var newContent =
                    content.substring(0, fullSectionIndex) +
                    fullSection +
                    appendData.toString() +
                    content.substring(insertionPosition);
                _textEditingController.text = newContent;
                widget.onDataChange?.call(newContent);
                _iniReader = IniReader(newContent, containsNotes: true);
              }
            }
          },
          dataSource: codeDataSource,
        );
      },
    );
  }

  //add
  void addDataInterpreter(DataInterpreter dataInterpreter, String keyValue) {
    _dataInterpreters.add(dataInterpreter);
    _dataInterpretersValues[dataInterpreter] = keyValue;
  }

  Widget _buildCoreWidget(BuildContext context) {
    var allSection = _iniReader!.getAllSection();
    _dataInterpreters.clear();
    var lineNumber = 0;
    List<Widget> sections = List.empty(growable: true);
    for (var fullSection in allSection) {
      //加入节的行号
      lineNumber++;
      final startLineNumber = lineNumber;
      final KeyValue sectionKeyValue = KeyValue();
      sectionKeyValue.isSection = true;
      sectionKeyValue.key = GlobalDepend.getSection(fullSection);
      final SectionInfo? sectionInfo = CodeDataBase.findSectionInfo(
        sectionKeyValue.key,
      );
      final SectionInterpreter sectionInterpreter = SectionInterpreter(
        sectionInfo: sectionInfo,
        lineNumber: startLineNumber,
        keyValue: sectionKeyValue,
        onLineDataChange: onLineDataChange,
        addCallBack: addCodeOrNote,
        editSequenceCallBack: editSequenceCallBack,
        displayLineNumber: widget.displayLineNumber,
        checkForRepetition: (fullSection) {
          var allSection = _iniReader!.getAllSection();
          if (allSection.isEmpty) {
            return false;
          }
          for (var value in allSection) {
            if (value == fullSection) {
              return true;
            }
          }
          return false;
        },
        displayOperationOptions: widget.displayOperationOptions,
        deletSectionCallBack: deletSectionCallBack,
      );
      addDataInterpreter(sectionInterpreter, fullSection);
      sections.add(sectionInterpreter);
      var keyValues = _iniReader!.getKeyValueInSection(
        fullSection,
        containsNotes: true,
      );
      var sectionPrefix = GlobalDepend.getSectionPrefix(fullSection);
      for (var kv in keyValues) {
        //加入键值对行号
        lineNumber++;
        if (kv.isNote) {
          var multipleLine = kv.value.contains("\n");
          String value = "";
          if (multipleLine) {
            value = "\"\"\"${kv.value}\"\"\"";
          } else {
            value = "#${kv.value}";
          }
          addDataInterpreter(
            NoteDataInterpreter(
              lineNumber: lineNumber,
              keyValue: kv,
              onLineDataChange: onLineDataChange,
              displayLineNumber: widget.displayLineNumber,
              displayOperationOptions: widget.displayOperationOptions,
            ),
            value,
          );
          continue;
        }
        var codeData = CodeDataBase.getCode(kv.key, sectionPrefix);
        if (codeData == null) {
          addDataInterpreter(
            getDefaultView(lineNumber, kv, null, null),
            getDefaultLineData(kv),
          );
        } else {
          addDataInterpreter(
            getCodeView(
              kv,
              lineNumber,
              codeData,
              CodeDataBase.getCodeInfo(kv.key, sectionPrefix),
            ),
            getDefaultLineData(kv),
          );
        }
      }
    }
    // _maxLineNumber
    if (lineNumber != _maxLineNumber) {
      _maxLineNumber = lineNumber;
      widget.onMaxLineNumberChange?.call(lineNumber);
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _modeVisual,
                label: Text(AppLocalizations.of(context)!.visual),
                icon: const Icon(Icons.view_compact_alt_outlined),
              ),
              ButtonSegment(
                value: _modeEditor,
                label: Text(AppLocalizations.of(context)!.editor),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
            selected: <int>{_mode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _mode = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _mode == _modeVisual ? 0 : 1,
            children: [
              _getVisualWidget(sections),
              TextField(
                onChanged: (s) {
                  widget.onDataChange?.call(s);
                  _iniReader = IniReader(s, containsNotes: true);
                },
                style: TextStyle(fontFamily: 'Mono'),
                expands: true,
                maxLines: null,
                controller: _textEditingController,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getVisualWidget(List<Widget> sections) {
    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Theme.of(context).iconTheme.color,
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noSectionWereDetected,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                addSection();
              },
              child: Text(AppLocalizations.of(context)!.addSection),
            ),
          ],
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: getSliverStickyHeader(_dataInterpreters),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  tooltip: AppLocalizations.of(context)!.showOrHideSidebar,
                  onPressed: () {
                    if (screenWidth < 600) {
                      widget.onRequestOpenDrawer.call();
                    } else {
                      widget.onRequestChangeLeftWidget.call();
                    }
                  },
                  icon: Icon(Icons.menu_open),
                ),

                IconButton(
                  tooltip: AppLocalizations.of(context)!.addSection,
                  onPressed: () {
                    addSection();
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> getSliverStickyHeader(List<Widget> sections) {
    final List<Map<String, dynamic>> sectionData = [];
    List<Widget> currentItems = [];
    Widget? currentSection;

    // 分组数据
    for (final widget in sections) {
      if (widget is SectionInterpreter) {
        if (currentSection != null) {
          sectionData.add({
            'section': currentSection,
            'items': currentItems.toList(),
          });
        }
        currentSection = widget;
        currentItems = [];
      } else {
        currentItems.add(widget);
      }
    }

    // 处理最后一组
    if (currentSection != null) {
      sectionData.add({
        'section': currentSection,
        'items': currentItems.toList(),
      });
    }

    // 构建 Sliver 列表
    return sectionData.map((data) {
      final section = data['section'] as Widget;
      final items = data['items'] as List<Widget>;

      return SliverStickyHeader(
        header: section,
        sliver: SliverList(delegate: SliverChildListDelegate(items)),
      );
    }).toList();
  }

  void addSection() async {
    var fileName = await GlobalDepend.getFileSystemOperator().name(
      widget.sourceFilePath,
    );
    if (mounted) {
      showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        builder: (c) {
          SectionDataSource sectionDataSource = SectionDataSource(
            AppLocalizations.of(context)!.addSectionTitle,
            AppLocalizations.of(context)!.searchByTitle,
            AppLocalizations.of(context)!.addSectionTip,
          );
          List<String> sectionNameList = List.empty(growable: true);
          if (_iniReader != null) {
            var existed = _iniReader!.getAllSection();
            for (String str in existed) {
              String sectionName = GlobalDepend.getSection(str);
              var sectionInfo = CodeDataBase.findSectionInfo(sectionName);
              if (sectionInfo == null) {
                continue;
              }
              sectionNameList.add(sectionName);
              sectionDataSource.existedList.add(sectionInfo);
            }
          }
          sectionDataSource.allList.addAll(
            CodeDataBase.getSectionInfoListByFileName(fileName),
          );
          return SearchMultipleSelectionDialog(
            onSelected: (selectedSectionList) {
              var content = _iniReader?.content;
              StringBuffer stringBuffer = StringBuffer();
              stringBuffer.write(content);
              for (dynamic section in selectedSectionList) {
                if (section is! SectionInfo) {
                  continue;
                }
                var hasName = section.hasName;
                if (hasName == null) {
                  continue;
                }
                if (stringBuffer.length != 0) {
                  stringBuffer.write('\n');
                }
                if (hasName) {
                  stringBuffer.write('[');
                  var index = 0;
                  var sectionName = section.section;
                  String? otherSectionName;
                  if (sectionName == "action") {
                    otherSectionName = "hiddenAction";
                  }
                  if (sectionName == "hiddenAction") {
                    otherSectionName = "action";
                  }
                  if (sectionName == "leg") {
                    otherSectionName = "arm";
                  }
                  if (sectionName == "arm") {
                    otherSectionName = "leg";
                  }
                  while (true) {
                    index++;
                    if (otherSectionName != null) {
                      var containsOther = sectionNameList.contains(
                        '${otherSectionName}_$index',
                      );
                      if (containsOther) {
                        continue;
                      }
                    }
                    var newName = '${sectionName}_$index';
                    var contains = sectionNameList.contains(newName);
                    if (contains) {
                      continue;
                    }
                    stringBuffer.write(newName);
                    break;
                  }
                  stringBuffer.write(']');
                  stringBuffer.write(additionalCode(section.section));
                } else {
                  stringBuffer.write('[');
                  stringBuffer.write(section.section);
                  stringBuffer.write(']');
                  stringBuffer.write(additionalCode(section.section));
                }
              }
              _textEditingController.text = stringBuffer.toString();
              widget.onDataChange?.call(stringBuffer.toString());
              _iniReader = IniReader(
                stringBuffer.toString(),
                containsNotes: true,
              );
            },
            dataSource: sectionDataSource,
          );
        },
      );
    }
  }

  String additionalCode(String? section) {
    if (section == "turret" || section == "leg" || section == "arm") {
      return "\nx: 0\ny: 0\n";
    }
    if (section == "projectile") {
      return "\nlife: 60\ndirectDamage: 10\n";
    }
    if (section == "canBuild") {
      return "\nname: c_tank\nforceNano: true\n";
    }
    return "";
  }

  String getDefaultLineData(KeyValue keyValue) {
    var value = keyValue.value.toString();
    var multipleLine = value.contains("\n");
    var stringBuffer = StringBuffer();
    stringBuffer.write(keyValue.key);
    stringBuffer.write(':');
    stringBuffer.write(' ');
    if (multipleLine) {
      if (!value.startsWith("\"\"\"")) {
        stringBuffer.write("\"\"\"");
      }
      stringBuffer.write(value);
      if (!value.endsWith("\"\"\"")) {
        stringBuffer.write("\"\"\"");
      }
    } else {
      stringBuffer.write(keyValue.value);
    }
    return stringBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorInfo != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorInfo!),
            SizedBox(height: 8),
            FilledButton(
              onPressed: () => {_loadFile()},
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _buildCoreWidget(context),
    );
  }

  DataInterpreter getDefaultView(
    int lineNumber,
    KeyValue keyValue,
    Code? codeData,
    CodeInfo? codeInfo,
  ) {
    return StringDataInterpreter(
      keyValue: keyValue,
      codeData: codeData,
      codeInfo: codeInfo,
      onLineDataChange: onLineDataChange,
      lineNumber: lineNumber,
      displayLineNumber: widget.displayLineNumber,
      displayOperationOptions: widget.displayOperationOptions,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
