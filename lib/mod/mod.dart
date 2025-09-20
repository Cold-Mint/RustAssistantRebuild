import 'dart:typed_data';

import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/mod/mod_reader.dart';

class Mod {
  //表示Mod的路径
  String path;

  Mod(this.path);

  String? modName;
  String? modDescription;
  Uint8List? icon;
  IModReader? _modReader;
  bool isDirectory = true;
  String? steamId;

  //加载Mod，返回是否加载成功
  Future<bool> load() async {
    var fileSystemOperator = GlobalDepend.getFileSystemOperator();
    bool exists = await fileSystemOperator.exist(path);
    if (!exists) {
      return false;
    }
    isDirectory = await fileSystemOperator.isDir(path);
    if (isDirectory) {
      _modReader = FolderModReader(path);
    } else {
      _modReader = ZipModReader(path);
    }
    await _modReader?.init();
    modName = await _modReader?.modName();
    modDescription = await _modReader?.modDescription();
    icon = await _modReader?.modIcon();
    steamId = await _modReader?.getSteamId();
    return true;
  }
}
