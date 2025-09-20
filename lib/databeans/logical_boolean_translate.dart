class LogicalBooleanTranslate {
  String? rule;
  String? translate;
  String? description;
  List<Argument>? argument;

  LogicalBooleanTranslate({
    this.rule,
    this.translate,
    this.description,
    this.argument,
  });

  LogicalBooleanTranslate.fromJson(Map<String, dynamic> json) {
    rule = json['rule'];
    translate = json['translate'];
    description = json['description'];
    if (json['argument'] != null) {
      argument = <Argument>[];
      json['argument'].forEach((v) {
        argument!.add(Argument.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rule'] = rule;
    data['translate'] = translate;
    data['description'] = description;
    if (argument != null) {
      data['argument'] = argument!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Argument {
  String? name;
  String? translate;

  Argument({this.name, this.translate});

  Argument.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    translate = json['translate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['translate'] = translate;
    return data;
  }
}
