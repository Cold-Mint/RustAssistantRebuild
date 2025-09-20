//可视化分析结果
import 'dart:typed_data';

class VisualAnalyticsResult {
  //分析开始时间
  DateTime? startTime;

  //分析结束时间
  DateTime? endTime;
  List<VisualAnalyticsResultItem> items = List.empty(growable: true);
  List<String> tagList = List.empty();
}

class VisualAnalyticsResultItem {
  //分析结果
  List<ListData> result = List.empty(growable: true);

  //分析结果标题
  String? title;
}

class ListData {
  String? title;
  String? subTitle;
  String? path;
  Uint8List? bytes;
}
