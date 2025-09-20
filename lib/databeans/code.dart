class Code {
  String? code;
  int? minVersion;
  int? maxVersion;
  String? section;
  String? interpreter;
  String? fileName;
  String? defaultKey;
  String? defaultValue;
  //是否允许重复，默认为false，如果允许重复，那么将在添加代码对话框内始终显示。
  bool? allowRepetition;

  Code({this.code, this.minVersion, this.maxVersion, this.section, this.interpreter, this.fileName, this.defaultKey, this.defaultValue, this.allowRepetition});

  Code.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    minVersion = json['minVersion'];
    maxVersion = json['maxVersion'];
    section = json['section'];
    interpreter = json['interpreter'];
    fileName = json['file_name'];
    defaultKey = json['default_key'];
    defaultValue = json['default_value'];
    allowRepetition = json['allow_repetition'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['minVersion'] = minVersion;
    data['maxVersion'] = maxVersion;
    data['section'] = section;
    data['interpreter'] = interpreter;
    data['file_name'] = fileName;
    data['default_key'] = defaultKey;
    data['default_value'] = defaultValue;
    data['allow_repetition'] = allowRepetition;
    return data;
  }
}