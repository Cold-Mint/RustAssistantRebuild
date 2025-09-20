class FuncParser {
  String content;

  FuncParser(this.content);

  /// 提取函数名
  String getFuncName() {
    // 匹配 xxx(...) 或 xxx（无括号）
    final regex = RegExp(r'^([a-zA-Z_][\w\.]*)');
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(1)!;
    }
    return '';
  }

  /// 提取参数内容（返回参数键值对）
  List<ArgumentData> getArguments() {
    final start = content.indexOf('(');
    final end = content.lastIndexOf(')');

    if (start != -1 && end != -1 && end > start) {
      final paramStr = content.substring(start + 1, end).trim();

      if (paramStr.isEmpty) return [];

      return _splitArgs(paramStr).map(_parseArgument).toList();
    }

    return [];
  }

  /// 将参数字符串拆分为 ['a=1', 'b=2'] 等
  List<String> _splitArgs(String paramStr) {
    List<String> args = [];
    int bracketLevel = 0;
    int quoteCount = 0;
    String current = '';

    for (int i = 0; i < paramStr.length; i++) {
      var char = paramStr[i];

      if (char == "'" || char == '"') {
        quoteCount = quoteCount == 0 ? 1 : 0;
      } else if (char == '(' || char == '[' || char == '{') {
        bracketLevel++;
      } else if (char == ')' || char == ']' || char == '}') {
        bracketLevel--;
      }

      if (char == ',' && bracketLevel == 0 && quoteCount == 0) {
        args.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    if (current.trim().isNotEmpty) {
      args.add(current.trim());
    }

    return args;
  }

  /// 将单个参数字符串解析为 Argument 实例
  ArgumentData _parseArgument(String arg) {
    final index = arg.indexOf('=');
    if (index == -1) {
      // 没有等号，作为 key，值设为空
      return ArgumentData(arg.trim(), '');
    } else {
      final key = arg.substring(0, index).trim();
      final value = arg.substring(index + 1).trim();
      return ArgumentData(key, value);
    }
  }
}


class ArgumentData {
  String key;
  String value;

  ArgumentData(this.key, this.value);
}
