class CodeInfo {
  String? code;
  String? translate;
  String? section;
  String? description;
  String? rule;

  CodeInfo({this.code, this.translate, this.section, this.description});

  CodeInfo.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    translate = json['translate'];
    section = json['section'];
    description = json['description'];
    rule = json['rule'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['translate'] = translate;
    data['section'] = section;
    data['description'] = description;
    data['rule'] = rule;
    return data;
  }
}
