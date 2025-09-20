import 'dart:convert';

Agreement agreementFromJson(String str) => Agreement.fromJson(json.decode(str));

String agreementToJson(Agreement data) => json.encode(data.toJson());

class Agreement {
    Agreement({
        required this.msg,
        required this.code,
        required this.data,
    });

    String msg;
    int code;
    Data data;

    factory Agreement.fromJson(Map<dynamic, dynamic> json) => Agreement(
        msg: json["msg"],
        code: json["code"],
        data: Data.fromJson(json["data"]),
    );

    Map<dynamic, dynamic> toJson() => {
        "msg": msg,
        "code": code,
        "data": data.toJson(),
    };
}

class Data {
    Data({
        required this.updateTime,
        required this.isDeleted,
        required this.createTime,
        required this.id,
        required this.title,
        required this.content,
    });

    int updateTime;
    bool isDeleted;
    int createTime;
    int id;
    String title;
    String content;

    factory Data.fromJson(Map<dynamic, dynamic> json) => Data(
        updateTime: json["update_time"],
        isDeleted: json["is_deleted"],
        createTime: json["create_time"],
        id: json["id"],
        title: json["title"],
        content: json["content"],
    );

    Map<dynamic, dynamic> toJson() => {
        "update_time": updateTime,
        "is_deleted": isDeleted,
        "create_time": createTime,
        "id": id,
        "title": title,
        "content": content,
    };
}
