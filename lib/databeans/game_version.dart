class GameVersion {
  int? versionCode;
  String? versionName;
  bool? visible;

  GameVersion({this.versionCode, this.versionName, this.visible});

  GameVersion.fromJson(Map<String, dynamic> json) {
    versionCode = json['version_code'];
    versionName = json['version_name'];
    visible = json['visible'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version_code'] = versionCode;
    data['version_name'] = versionName;
    data['visible'] = visible;
    return data;
  }
}
