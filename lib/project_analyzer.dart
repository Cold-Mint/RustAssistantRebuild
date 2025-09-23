import 'package:rust_assistant/databeans/unit_ref.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';

import 'databeans/visual_analytics_result.dart';

import 'file_operator/file_operator.dart';
import 'l10n/app_localizations.dart';
import 'mod/line_parser.dart';

class ProjectAnalyzer {
  String rootPath;
  FileSystemOperator fileSystemOperator;
  bool _isRunning = false;
  VisualAnalyticsResult? _lastResult;
  final List<UnitRef> unitRefList = List.empty(growable: true);

  ProjectAnalyzer(this.rootPath, this.fileSystemOperator);

  VisualAnalyticsResult? get lastResult => _lastResult;

  Future<void> analyze(
    AppLocalizations appLocalizations,
    Function? onStart,
    bool Function(int, String)? progress,
    Function(VisualAnalyticsResult? result)? onFinish,
  ) async {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    if (!await fileSystemOperator.isDir(rootPath)) {
      return;
    }
    var result = VisualAnalyticsResult();
    result.startTime = DateTime.now();
    onStart?.call();
    List<UnitRef> temporary = List.empty(growable: true);
    var fileVisualAnalytics = VisualAnalyticsResultItem();
    var assetsVisualAnalytics = VisualAnalyticsResultItem();
    var memoryVisualAnalytics = VisualAnalyticsResultItem();
    var tagVisualAnalytics = VisualAnalyticsResultItem();
    var unitVisualAnalytics = VisualAnalyticsResultItem();
    fileVisualAnalytics.title = appLocalizations.file;
    assetsVisualAnalytics.title = appLocalizations.assets;
    memoryVisualAnalytics.title = appLocalizations.memory;
    tagVisualAnalytics.title = appLocalizations.tags;
    unitVisualAnalytics.title = appLocalizations.unit;
    int index = 0;
    Set<String> tagSet = {};
    var languageDisplayText =
        "displayText_${HiveHelper.get(HiveHelper.language)}".toLowerCase();
    await fileSystemOperator.list(rootPath, (path) async {
      if (await fileSystemOperator.isDir(path)) {
        return false;
      }
      var fileHead = await FileTypeChecker.readFileHeader(path);
      var fileType = FileTypeChecker.getFileType(path, fileHeader: fileHead);
      index++;
      var relativePath = await fileSystemOperator.relative(path, rootPath);
      if (progress?.call(index, relativePath) == true) {
        return true;
      }
      var fileListData = ListData();
      fileListData.title = await fileSystemOperator.name(path);
      fileListData.subTitle = relativePath;
      fileListData.path = path;
      fileVisualAnalytics.result.add(fileListData);
      if (fileType == FileTypeChecker.FileTypeUnknown) {
        return false;
      }
      if (fileType == FileTypeChecker.FileTypeImage) {
        fileListData.bytes = await fileSystemOperator.readAsBytes(path);
        assetsVisualAnalytics.result.add(fileListData);
        return false;
      }
      if (fileType == FileTypeChecker.FileTypeAudio) {
        assetsVisualAnalytics.result.add(fileListData);
        return false;
      }
      if (fileType == FileTypeChecker.FileTypeArchive) {
        return false;
      }
      UnitRef unitRef = UnitRef();
      unitRef.path = path;
      var text = await fileSystemOperator.readAsString(path) ?? "";
      var lineParser = LineParser(text);
      String? section;
      while (true) {
        var line = lineParser.nextLine();
        if (line == null) {
          break;
        }
        if (line.startsWith("[") && line.endsWith("]")) {
          section = GlobalDepend.getSectionPrefix(line);
          continue;
        }
        var lineLowerCase = line.toLowerCase();
        if (lineLowerCase.contains("memory")) {
          var memoryListData = ListData();
          memoryListData.title = line;
          memoryListData.subTitle = relativePath;
          memoryListData.path = path;
          memoryVisualAnalytics.result.add(memoryListData);
        }
        var symbol = lineLowerCase.indexOf(':');
        if (symbol > -1) {
          var keyName = lineLowerCase.substring(0, symbol);
          if (keyName == "tags") {
            var tagListData = ListData();
            tagListData.title = line;
            tagListData.subTitle = relativePath;
            tagListData.path = path;
            tagVisualAnalytics.result.add(tagListData);
            var value = line.substring(symbol + 1).trim();
            var valueList = value.split(',');
            for (var tag in valueList) {
              var tgaTrim = tag.trim();
              if (!tagSet.contains(tgaTrim)) {
                tagSet.add(tgaTrim);
              }
            }
          } else if (section == "core" && keyName == "name") {
            unitRef.name = line.substring(symbol + 1).trim();
          } else if (unitRef.displayName == null &&
              section == "core" &&
              keyName == "displaytext") {
            unitRef.displayName = line.substring(symbol + 1).trim();
          } else if (section == "core" && keyName == languageDisplayText) {
            unitRef.displayName = line.substring(symbol + 1).trim();
          }
        }
      }
      if (unitRef.name != null) {
        temporary.add(unitRef);
        var unitData = ListData();
        unitData.title = unitRef.name;
        unitData.subTitle = relativePath;
        unitData.path = path;
        unitVisualAnalytics.result.add(unitData);
      }
      return false;
    }, recursive: true);
    result.items.add(fileVisualAnalytics);
    result.items.add(assetsVisualAnalytics);
    result.items.add(memoryVisualAnalytics);
    result.items.add(tagVisualAnalytics);
    result.items.add(unitVisualAnalytics);
    unitRefList.clear();
    unitRefList.addAll(temporary);
    result.tagList = tagSet.toList();
    result.endTime = DateTime.now();
    _lastResult = result;
    _isRunning = false;
    onFinish?.call(result);
  }
}
