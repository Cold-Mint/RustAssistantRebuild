class LanguageCode {
  String? code;
  String? translate;

  LanguageCode({this.code, this.translate});

  LanguageCode.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    translate = json['translate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['translate'] = translate;
    return data;
  }
}
