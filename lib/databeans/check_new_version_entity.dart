class CheckNewVersionEntity {
  int? code;
  String? msg;
  Data? data;

  CheckNewVersionEntity({this.code, this.msg, this.data});

  CheckNewVersionEntity.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['msg'] = msg;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class Data {
  int? createTime;
  String? description;
  bool? enable;
  bool? forcedUpdate;
  String? id;
  bool? preRelease;
  String? versionName;
  int? versionNumber;

  Data({
    this.createTime,
    this.description,
    this.enable,
    this.forcedUpdate,
    this.id,
    this.preRelease,
    this.versionName,
    this.versionNumber,
  });

  Data.fromJson(Map<String, dynamic> json) {
    createTime = json['create_time'];
    description = json['description'];
    enable = json['enable'];
    forcedUpdate = json['forced_update'];
    id = json['id'];
    preRelease = json['pre_release'];
    versionName = json['version_name'];
    versionNumber = json['version_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['create_time'] = createTime;
    data['description'] = description;
    data['enable'] = enable;
    data['forced_update'] = forcedUpdate;
    data['id'] = id;
    data['pre_release'] = preRelease;
    data['version_name'] = versionName;
    data['version_number'] = versionNumber;
    return data;
  }
}
