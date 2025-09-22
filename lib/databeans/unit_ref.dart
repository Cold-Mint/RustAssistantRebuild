class UnitRef {
  String? description;
  String? displayName;
  String? name;
  String? path;

  UnitRef({this.description, this.displayName, this.name, this.path});

  UnitRef.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    displayName = json['displayName'];
    name = json['name'];
    path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['displayName'] = displayName;
    data['name'] = name;
    data['path'] = path;
    return data;
  }
}
