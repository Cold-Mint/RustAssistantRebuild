class DownloadLink {
  int? code;
  String? msg;
  Data? data;

  DownloadLink({this.code, this.msg, this.data});

  DownloadLink.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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
  int? createAt;
  String? downloadLink;
  int? expiredAt;

  Data({this.createAt, this.downloadLink, this.expiredAt});

  Data.fromJson(Map<String, dynamic> json) {
    createAt = json['create_at'];
    downloadLink = json['download_link'];
    expiredAt = json['expired_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['create_at'] = createAt;
    data['download_link'] = downloadLink;
    data['expired_at'] = expiredAt;
    return data;
  }
}