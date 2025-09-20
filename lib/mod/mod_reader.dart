import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/mod/ini_reader.dart';

//mod读取器
abstract class IModReader {
  Future<String> modName();

  Future init();

  Future<String?> modDescription();

  Future<Uint8List?> modIcon();

  Future<String?> getSteamId();
}

//用于读取解压好的Mod
class FolderModReader implements IModReader {
  String path;
  IniReader? _modInfoReader;
  IniReader? _steamBatReader;

  FolderModReader(this.path);

  @override
  Future<String> modName() async {
    if (_modInfoReader == null) {
      return p.basename(path);
    }
    var title = _modInfoReader?.getKey("title");
    if (title == null) {
      return p.basename(path);
    } else {
      return title;
    }
  }

  @override
  Future<String?> modDescription() async {
    return _modInfoReader?.getKey("description");
  }

  @override
  Future init() async {
    FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    var modInfoFile = fileSystemOperator.join(path, Constant.modInfoFileName);
    bool modInfoExists = await fileSystemOperator.exist(modInfoFile);
    if (modInfoExists) {
      _modInfoReader = IniReader(
        await fileSystemOperator.readAsString(modInfoFile) ?? "",
      );
    }

    var steamBatFile = fileSystemOperator.join(path, Constant.steamBatFileName);
    bool steamBatExists = await fileSystemOperator.exist(steamBatFile);
    if (steamBatExists) {
      _steamBatReader = IniReader(
        await fileSystemOperator.readAsString(steamBatFile) ?? "",
      );
    }
  }

  @override
  Future<Uint8List?> modIcon() async {
    if (_modInfoReader == null) {
      return null;
    }
    var thumbnail = _modInfoReader?.getKey("thumbnail");
    if (thumbnail == null) {
      return null;
    }
    FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    var iconPath = fileSystemOperator.join(path, thumbnail);
    if (!await fileSystemOperator.exist(iconPath)) {
      return null;
    }
    return fileSystemOperator.readAsBytes(iconPath);
  }

  @override
  Future<String?> getSteamId() async {
    return _steamBatReader?.getKey("id");
  }
}

//用于读取未解压的Mod
class ZipModReader implements IModReader {
  String path;
  IniReader? _modInfoReader;
  IniReader? _steamBatReader;
  late ZipFileOperator _zipFileOperator;

  ZipModReader(this.path);

  @override
  Future<String> modName() async {
    if (_modInfoReader == null) {
      return p.basename(path);
    }
    var title = _modInfoReader?.getKey("title");
    if (title == null) {
      return p.basename(path);
    } else {
      return title;
    }
  }

  @override
  Future<String?> modDescription() async {
    return _modInfoReader?.getKey("description");
  }

  @override
  Future init() async {
    _zipFileOperator = ZipFileOperator();
    var archivedFileLoadingLimit = HiveHelper.get(
      HiveHelper.archivedFileLoadingLimit,
    );
    int size = await GlobalDepend.getFileSystemOperator().size(path);
    if (size > archivedFileLoadingLimit) {
      return;
    }
    Uint8List? byte = await GlobalDepend.getFileSystemOperator().readAsBytes(
      path,
    );
    if (byte == null) {
      return;
    }
    _zipFileOperator.decodeBytes(byte.toList());
    bool modInfoExists = await _zipFileOperator.exist(Constant.modInfoFileName);
    if (modInfoExists) {
      _modInfoReader = IniReader(
        await _zipFileOperator.readAsString(Constant.modInfoFileName) ?? "",
      );
    }

    var steamBatFile = _zipFileOperator.join(path, Constant.steamBatFileName);
    bool steamBatExists = await _zipFileOperator.exist(steamBatFile);
    if (steamBatExists) {
      _steamBatReader = IniReader(
        await _zipFileOperator.readAsString(steamBatFile) ?? "",
      );
    }
  }

  @override
  Future<String?> getSteamId() async {
    return _steamBatReader?.getKey("id");
  }

  @override
  Future<Uint8List?> modIcon() async {
    if (_modInfoReader == null) {
      return null;
    }
    var thumbnail = _modInfoReader?.getKey("thumbnail");
    if (thumbnail == null) {
      return null;
    }
    if (!await _zipFileOperator.exist(thumbnail)) {
      return null;
    }
    return _zipFileOperator.readAsBytes(thumbnail);
  }
}
