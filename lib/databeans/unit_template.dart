class UnitTemplate {
  String? language;
  List<Templates>? templates;

  UnitTemplate({this.language, this.templates});

  UnitTemplate.fromJson(Map<String, dynamic> json) {
    language = json['language'];
    if (json['templates'] != null) {
      templates = List<Templates>.empty(growable: true);
      json['templates'].forEach((v) {
        templates?.add(Templates.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['language'] = language;
    if (templates != null) {
      data['templates'] = templates?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Templates {
  String? path;
  String? name;

  Templates({this.path, this.name});

  Templates.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['name'] = name;
    return data;
  }
}
