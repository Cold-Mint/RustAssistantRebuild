class IniWriter {
  /// 替换 INI 中指定节的内容，或在不存在时追加。
  /// [original] 是原始 ini 文本
  /// [sectionName] 是完整节名（如 "[core]"）
  /// [content] 是格式化好的节内容字符串，支持多行
  static String writeSection({
    required String original,
    required String sectionName,
    required String content,
  }) {
    final lines = original.split('\n');
    final buffer = StringBuffer();
    bool sectionWritten = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed == sectionName) {
        sectionWritten = true;
        buffer.writeln(sectionName);

        // 写入传入的新节内容
        buffer.writeln(content.trimRight());

        // 跳过旧节内容
        i++;
        while (i < lines.length) {
          final nextTrim = lines[i].trim();
          if (nextTrim.startsWith('[') && nextTrim.endsWith(']')) {
            i--; // 回退一行让下一轮处理节头
            break;
          }
          i++;
        }
        continue;
      }

      // 其他内容正常写入
      buffer.writeln(line);
    }

    // 如果节没出现过，追加到末尾
    if (!sectionWritten) {
      buffer.writeln(); // 空行隔开
      buffer.writeln(sectionName);
      buffer.writeln(content.trimRight());
    }

    return buffer.toString();
  }

  static String removeSection(String content, String fullSectionName) {
    final lines = content.split(RegExp(r'\r?\n'));
    final buffer = StringBuffer();
    final sectionHeader = '[$fullSectionName]';
    bool inTargetSection = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        // 碰到新 section
        if (trimmed.toLowerCase() == sectionHeader.toLowerCase()) {
          inTargetSection = true;
          continue; // 跳过不写入
        } else {
          inTargetSection = false;
        }
      }

      if (!inTargetSection) {
        buffer.writeln(line);
      }
    }

    // 去掉最后多余的换行
    var result = buffer.toString();
    if (result.endsWith('\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
