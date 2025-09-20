class RecycleBinItem {
  String? path;
  String? name;
  String? recycleBinPath;
  int? count;

  RecycleBinItem({this.path, this.name, this.recycleBinPath});

  RecycleBinItem.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    name = json['name'];
    recycleBinPath = json['recycleBinPath'];
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['path'] = path;
    data['name'] = name;
    data['recycleBinPath'] = recycleBinPath;
    data['count'] = count;
    return data;
  }
}
