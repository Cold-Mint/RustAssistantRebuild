//项目分析器

import 'package:rust_assistant/file_type_checker.dart';

import 'databeans/visual_analytics_result.dart';

import 'file_operator/file_operator.dart';
import 'l10n/app_localizations.dart';
import 'mod/line_parser.dart';

class ProjectAnalyzer {
  String rootPath;
  FileSystemOperator fileSystemOperator;
  bool _isRunning = false;
  VisualAnalyticsResult? _lastResult;

  ProjectAnalyzer(this.rootPath, this.fileSystemOperator);

  VisualAnalyticsResult? get lastResult => _lastResult;

  //分析项目
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
    //开始分析rootPath是一个文件夹目录，遍历下面的每一个文件
    //文件可视化分析器项目
    var fileVisualAnalytics = VisualAnalyticsResultItem();
    var assetsVisualAnalytics = VisualAnalyticsResultItem();
    var memoryVisualAnalytics = VisualAnalyticsResultItem();
    var tagVisualAnalytics = VisualAnalyticsResultItem();
    fileVisualAnalytics.title = appLocalizations.file;
    assetsVisualAnalytics.title = appLocalizations.assets;
    memoryVisualAnalytics.title = appLocalizations.memory;
    tagVisualAnalytics.title = appLocalizations.tags;
    int index = 0;
    Set<String> tagSet = {};
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
      if(fileType == FileTypeChecker.FileTypeArchive){
        return false;
      }
      var text = await fileSystemOperator.readAsString(path) ?? "";
      var lineParser = LineParser(
        text
      );
      while (true) {
        var line = lineParser.nextLine();
        if (line == null) {
          break;
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
            //解析value
            var value = line.substring(symbol + 1).trim();
            var valueList = value.split(',');
            for (var tag in valueList) {
              var tgaTrim = tag.trim();
              if (!tagSet.contains(tgaTrim)) {
                tagSet.add(tgaTrim);
              }
            }
          }
        }
      }
      return false;
    }, recursive: true);
    result.items.add(fileVisualAnalytics);
    result.items.add(assetsVisualAnalytics);
    result.items.add(memoryVisualAnalytics);
    result.items.add(tagVisualAnalytics);
    result.tagList = tagSet.toList();
    result.endTime = DateTime.now();
    _lastResult = result;
    _isRunning = false;
    onFinish?.call(result);
  }
}
