class SectionInfo {
  String? section;
  String? translate;
  String? fileName;
  bool? hasName;
  String? rule;

  SectionInfo({
    this.section,
    this.translate,
    this.fileName,
    this.hasName,
    this.rule,
  });

  SectionInfo.fromJson(Map<String, dynamic> json) {
    section = json['section'];
    translate = json['translate'];
    fileName = json['file_name'];
    hasName = json['has_name'];
    rule = json['rule'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['section'] = section;
    data['translate'] = translate;
    data['file_name'] = fileName;
    data['has_name'] = hasName;
    data['rule'] = rule;
    return data;
  }
}
