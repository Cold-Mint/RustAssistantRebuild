import '../databeans/key_value.dart';
import 'line_parser.dart';

class IniReader {
  final String content;

  List<String> lines = List.empty(growable: true);

  //可选的包含空行和注释
  IniReader(
    this.content, {
    bool containsBlankLines = false,
    bool containsNotes = false,
  }) {
    var lineParser = LineParser(content);
    while (true) {
      var line = lineParser.nextLine();
      if (line == null) {
        break;
      }
      var trimValue = line.trim();
      if (!containsBlankLines && trimValue.isEmpty) {
        continue;
      }
      if (!containsNotes && trimValue.startsWith("#")) {
        continue;
      }
      lines.add(trimValue);
    }
  }

  //获取源文件内的所有节，以数组返回，元素为[code]
  List<String> getAllSection() {
    List<String> section = List.empty(growable: true);
    for (var line in lines) {
      var trimLine = line.trim();
      if (trimLine.startsWith("[") && trimLine.endsWith("]")) {
        if (!section.contains(trimLine)) {
          section.add(trimLine);
        }
      }
    }
    return section;
  }

  //获取某个节内的所有keyValue值(包含注释)
  List<KeyValue> getKeyValueInSection(
    String sectionName, {
    bool fullSectionName = true,
    bool containsNotes = false,
  }) {
    List<KeyValue> keyList = List.empty(growable: true);
    var section = sectionName;
    if (!fullSectionName) {
      section = "[$sectionName]";
    }
    var add = false;
    for (var line in lines) {
      var trimLine = line.trim();
      if (trimLine == section) {
        add = true;
        continue;
      }
      if (!add) {
        continue;
      }
      if (trimLine.startsWith("[") && trimLine.endsWith("]")) {
        add = false;
        continue;
      }

      KeyValue? keyValue = getKeyValue(line);
      if (keyValue.isNote && !containsNotes) {
        continue;
      }
      keyList.add(keyValue);
    }
    return keyList;
  }

  //在行信息内获取keyValue对象，注意：line内可能包含换行。（如果行是空的或者以#开头再或者不包含：则返回注释）
  static KeyValue getKeyValue(String line) {
    var trimLine = line.trim();
    var keyValue = KeyValue();
    if (trimLine.isEmpty) {
      keyValue.isNote = true;
      keyValue.value = "";
      return keyValue;
    }
    if (trimLine.startsWith("#")) {
      keyValue.isNote = true;
      keyValue.value = trimLine.substring(1);
      return keyValue;
    }
    if (trimLine.startsWith("\"\"\"") && trimLine.endsWith("\"\"\"")) {
      keyValue.isNote = true;
      keyValue.value = trimLine.substring(3, trimLine.length - 3);
      return keyValue;
    }
    var index = trimLine.indexOf(':');
    if (index < 0) {
      keyValue.isNote = true;
      keyValue.value = trimLine;
      return keyValue;
    }
    var key = trimLine.substring(0, index).trim();
    var value = trimLine.substring(index + 1).trim();
    keyValue.key = key;
    keyValue.value = value.replaceAll("\"\"\"", "");
    return keyValue;
  }

  String? getKey(String key, {bool containsNotes = false}) {
    for (var line in lines) {
      KeyValue keyValue = getKeyValue(line);
      if (keyValue.isNote && !containsNotes) {
        continue;
      }
      if (keyValue.key == key) {
        return keyValue.value;
      }
    }
    return null;
  }

  KeyValue? getKeyValueFromSection(
    String sectionName,
    String key, {
    bool fullSectionName = true,
    bool containsNotes = false,
  }) {
    final List<KeyValue> keyList = getKeyValueInSection(
      sectionName,
      fullSectionName: fullSectionName,
      containsNotes: containsNotes,
    );
    for (var keyValue in keyList) {
      if (keyValue.key == key) {
        return keyValue;
      }
    }
    return null;
  }
}
