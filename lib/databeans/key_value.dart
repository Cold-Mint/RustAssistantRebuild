class KeyValue {
  String key = "";
  bool isNote = false;
  bool isSection = false;
  dynamic value;

  String getLineData() {
    var strValue = value.toString();
    var multipleLine = strValue.contains("\n");
    StringBuffer stringBuffer = StringBuffer();
    if (isNote) {
      if (multipleLine) {
        stringBuffer.write("\"\"\"");
        if (key.isNotEmpty) {
          stringBuffer.write(key);
          stringBuffer.write(':');
          stringBuffer.write(' ');
        }
        stringBuffer.write(strValue.replaceAll("\"\"\"", ""));
        stringBuffer.write("\"\"\"");
      } else {
        stringBuffer.write("#");
        if (key.isNotEmpty) {
          stringBuffer.write(key);
          stringBuffer.write(':');
          stringBuffer.write(' ');
        }
        stringBuffer.write(strValue);
      }
      return stringBuffer.toString();
    }
    stringBuffer.write(key);
    stringBuffer.write(':');
    stringBuffer.write(' ');
    if (multipleLine) {
      if (!strValue.startsWith("\"\"\"")) {
        stringBuffer.write("\"\"\"");
      }
      stringBuffer.write(strValue);
      if (!strValue.endsWith("\"\"\"")) {
        stringBuffer.write("\"\"\"");
      }
    } else {
      stringBuffer.write(strValue);
    }
    return stringBuffer.toString();
  }

  void update(KeyValue newKeyValue) {
    key = newKeyValue.key;
    isNote = newKeyValue.isNote;
    isSection = newKeyValue.isSection;
    value = newKeyValue.value;
  }
}
