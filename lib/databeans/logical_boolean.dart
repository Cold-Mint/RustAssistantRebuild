class LogicalBoolean {
  String? name;
  String? rule;
  String? returnValue;
  String? interpreter;
  String? noParametersReturn;
  int? minVersion;
  int? maxVersion;
  bool? isFunction;
  List<Argument>? argument;

  LogicalBoolean({
    required this.name,
    required this.rule,
    required this.returnValue,
    required this.interpreter,
    required this.noParametersReturn,
    required this.minVersion,
    required this.maxVersion,
    required this.isFunction,
    required this.argument,
  });

  LogicalBoolean.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    rule = json['rule'];
    returnValue = json['returnValue'];
    interpreter = json['interpreter'];
    noParametersReturn = json['noParametersReturn'];
    minVersion = json['minVersion'];
    maxVersion = json['maxVersion'];
    isFunction = json['isFunction'];
    if (json['argument'] != null) {
      argument = List<Argument>.empty(growable: true);
      json['argument'].forEach((v) {
        argument?.add(Argument.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['rule'] = rule;
    data['returnValue'] = returnValue;
    data['interpreter'] = interpreter;
    data['noParametersReturn'] = noParametersReturn;
    data['minVersion'] = minVersion;
    data['maxVersion'] = maxVersion;
    data['isFunction'] = isFunction;
    data['argument'] = argument?.map((v) => v.toJson()).toList();
    return data;
  }
}

class Argument {
  bool? isRequired;
  String? type;
  String? name;
  int? number;

  Argument({this.isRequired, this.type, this.name, this.number});

  Argument.fromJson(Map<String, dynamic> json) {
    isRequired = json['isRequired'];
    type = json['type'];
    name = json['name'];
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isRequired'] = isRequired;
    data['type'] = type;
    data['name'] = name;
    data['number'] = number;
    return data;
  }
}
