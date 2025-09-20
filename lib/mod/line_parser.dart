class LineParser {
  final String content;
  final List<String> _lines;
  int _index = 0;

  static final RegExp _tripleQuoteReg = RegExp(r'"""');

  LineParser(this.content) : _lines = content.split('\n');

  String? nextLine() {
    if (_index >= _lines.length) return null;

    final line = _lines[_index];

    // 检查是否包含多行文本起始
    if (line.contains(_tripleQuoteReg)) {
      final buffer = StringBuffer();
      int quoteCount = _countQuotes(line);

      buffer.write(line);
      buffer.write('\n');
      _index++;

      // 如果是同一行内 """...""" 则直接处理
      if (quoteCount == 2) {
        return _stripTripleQuotes(buffer.toString());
      }

      // 否则拼接后续行，直到匹配成对的 """
      while (_index < _lines.length) {
        final next = _lines[_index];
        quoteCount += _countQuotes(next);
        buffer.write(next);
        buffer.write('\n');
        _index++;

        if (quoteCount >= 2 && quoteCount % 2 == 0) {
          break;
        }
      }

      return _stripTripleQuotes(buffer.toString());
    } else {
      // 普通行
      _index++;
      return line;
    }
  }

  int _countQuotes(String line) {
    return _tripleQuoteReg.allMatches(line).length;
  }

  String _stripTripleQuotes(String text) {
    return text.trim();
  }
}