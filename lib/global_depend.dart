import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pinyin/pinyin.dart';
import 'package:provider/provider.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/recycle_bin_item.dart';
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/mod/mod.dart';
import 'package:uuid/uuid.dart';

import 'constant.dart';
import 'locale_manager.dart';

class GlobalDepend {
  static final dio = Dio();
  static final List<RecycleBinItem> _recycleBinList = List.empty(
    growable: true,
  );

  static final FileSystemOperator _fileSystemOperator = LocalFileOperator();

  //是否允许读取文件魔数
  static bool readMagicNumberOfFiles = false;
  static List<RecycleBinItem> getRecycleBinList() {
    return _recycleBinList;
  }

  static Future loadRecycleBinList() async {
    var userDataFolder = await getUserDataFolder();
    if (userDataFolder == null) {
      return null;
    }
    var recycleBinJson = p.join(userDataFolder, Constant.recycleBinConfigFile);
    if (!await _fileSystemOperator.exist(recycleBinJson)) {
      return;
    }
    var text = await _fileSystemOperator.readAsString(recycleBinJson);
    if (text == null) {
      return;
    }
    _recycleBinList.clear();
    final List<dynamic> jsonData = json.decode(text);
    for (var item in jsonData) {
      _recycleBinList.add(RecycleBinItem.fromJson(item));
    }
  }

  static Future clearRecycleBinList() async {
    _recycleBinList.clear();
    await saveRecycleBinList();
  }

  static Future removeRecycleBinItem(RecycleBinItem item) async {
    _recycleBinList.remove(item);
    await saveRecycleBinList();
  }

  static Future saveRecycleBinList() async {
    var userDataFolder = await getUserDataFolder();
    if (userDataFolder == null) {
      return null;
    }
    var text = json.encode(_recycleBinList);
    await _fileSystemOperator.writeFile(
      userDataFolder,
      Constant.recycleBinConfigFile,
      text,
    );
  }

  //获取文件操作器
  static FileSystemOperator getFileSystemOperator() {
    return _fileSystemOperator;
  }

  //检查路径是否不可用
  static Future<bool> checkPathNormal() async {
    bool available = true;
    if (HiveHelper.containsKey(HiveHelper.modPath)) {
      var modPath = HiveHelper.get(HiveHelper.modPath);
      var exist = await _fileSystemOperator.exist(modPath);
      if (!exist) {
        //弹出路径失效对话框
        available = false;
      }
    }
    if (available && HiveHelper.containsKey(HiveHelper.showSteamMod)) {
      var showSteam = HiveHelper.get(HiveHelper.showSteamMod);
      if (showSteam) {
        if (!HiveHelper.containsKey(HiveHelper.steamModPath)) {
          //启用了steam，但是没有设置路径
          available = false;
        }
        var steamPath = HiveHelper.get(HiveHelper.steamModPath);
        var existSteam = await _fileSystemOperator.exist(steamPath);
        if (available && !existSteam) {
          available = false;
        }
      }
    }
    return available;
  }

  static Future<String?> getUserDataFolder() async {
    var userHomeDirectory = await getUserHomeDirectory();
    if (userHomeDirectory == null) {
      return null;
    }
    if (Platform.isLinux || Platform.isWindows) {
      return p.join(userHomeDirectory, ".rust-assistant");
    }
    if (Platform.isAndroid) {
      return p.join(userHomeDirectory, "rust-assistant");
    }
    return userHomeDirectory;
  }

  static Future<String?> getRecycleBinDirectory() async {
    var userHome = await getUserDataFolder();
    if (userHome == null) {
      return null;
    }
    return p.join(userHome, "recycleBin");
  }

  //是否为合法文件名
  static bool isValidFileName(String fileName) {
    return !RegExp(r'[<>:"/\\|?*\x00]').hasMatch(fileName);
  }

  static String getSecureFileName(String name) {
    if (name.isEmpty) return name;
    StringBuffer stringBuffer = StringBuffer();
    for (final ch in name.characters) {
      if (isChinese(ch)) {
        stringBuffer.write(PinyinHelper.getPinyin(ch));
      } else {
        stringBuffer.write(ch);
      }
    }
    return stringBuffer.toString();
  }

  static bool isChinese(String text) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
  }

  static String switchToRelativePath(
    String modPath,
    String sourceFilePath,
    String absolutePath,
  ) {
    var absolutePathLowCase = absolutePath.toLowerCase();
    if (absolutePathLowCase.startsWith(Constant.pathPrefixRoot) ||
        absolutePathLowCase.startsWith(Constant.pathPrefixCore) ||
        absolutePathLowCase.startsWith(Constant.pathPrefixShared)) {
      return absolutePath;
    }
    return Constant.pathPrefixRoot.toUpperCase() +
        p.relative(absolutePath, from: modPath);
  }

  static bool isFromSteam(Mod mod) {
    if (!HiveHelper.get(HiveHelper.showSteamMod)) {
      return false;
    }
    final steamModPath = HiveHelper.get(HiveHelper.steamModPath);
    if (steamModPath.isEmpty) {
      return false;
    }
    return mod.path.startsWith(steamModPath);
  }

  static Widget getIcon(BuildContext context, Mod mod) {
    final iconFile = mod.icon;
    final fromSteam = isFromSteam(mod);

    Widget baseIcon = ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 32,
        height: 32,
        child: iconFile == null
            ? Icon(Icons.image_outlined, size: 32)
            : Image.memory(
                iconFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported_outlined),
              ),
      ),
    );
    if (!mod.isDirectory) {
      return Stack(
        children: [
          baseIcon,
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.archive_outlined,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (fromSteam) {
      return Stack(
        children: [
          baseIcon,
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomRight: Radius.circular(8),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.public_outlined,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return baseIcon;
  }

  static Future<Mod?> convertToMod(String path) async {
    var dir = await _fileSystemOperator.isDir(path);
    if (dir) {
      Mod mod = Mod(path);
      await mod.load();
      return mod;
    }
    var head = await FileTypeChecker.readFileHeader(path);
    var fileType = FileTypeChecker.getFileType(path, fileHeader: head);
    if (fileType == FileTypeChecker.FileTypeArchive) {
      Mod mod = Mod(path);
      await mod.load();
      return mod;
    }
    return null;
  }

  //转换到绝对目录
  static String switchToAbsolutePath(
    String modPath,
    String sourceFilePath,
    String data,
  ) {
    var body = data.replaceAll("\\", "/");
    var lowCaseData = body.toLowerCase();
    if (lowCaseData.startsWith(Constant.pathPrefixRoot)) {
      body = body.substring(Constant.pathPrefixRoot.length);
      if (body.startsWith("/")) {
        body = body.substring(1);
      }
      return p.join(modPath, body);
    }
    if (lowCaseData.startsWith(Constant.pathPrefixCore)) {
      body = body.substring(Constant.pathPrefixCore.length);
      if (body.startsWith("/")) {
        body = body.substring(1);
      }
      return CodeDataBase.getCorePath(body);
    }
    if (lowCaseData.startsWith(Constant.pathPrefixShared)) {
      body = body.substring(Constant.pathPrefixShared.length);
      if (body.startsWith("/")) {
        body = body.substring(1);
      }
      return CodeDataBase.getSharedPath(body);
    }
    return p.join(p.dirname(sourceFilePath), body);
  }

  static Widget getFileIcon(bool isDirectory, String path, Uint8List? bytes) {
    if (isDirectory) {
      return Icon(Icons.folder_outlined);
    }

    if (bytes != null) {
      if (FileTypeChecker.getFileType(path, fileHeader: bytes) ==
          FileTypeChecker.FileTypeImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0), // 设置圆角
          child: Image.memory(
            bytes,
            width: 24.0, // 图像宽度
            height: 24.0, // 图像高度
            fit: BoxFit.cover, // 图像填充方式
          ),
        );
      }
    }

    String fileName = p.basename(path).toLowerCase();
    if (fileName == Constant.allUnitsTemplate) {
      return Icon(Icons.dataset_linked_outlined);
    } else if (fileName == Constant.modInfoFileName) {
      return Icon(Icons.file_open_outlined);
    }
    // 如果不是图像文件，返回默认文件图标
    return Icon(Icons.insert_drive_file_outlined);
  }

  //移动至回收站（返回值1，移动成功，0移动失败，2，操作被用户取消。）
  static Future<int> moveToRecycleBin(
    String path, {
    Future<bool> Function(String fileName, int current, int total, int status)?
    onProgress,
  }) async {
    final recycleBin = await getRecycleBinDirectory();
    if (recycleBin == null) {
      return Constant.moveToRecycleBinFail;
    }
    final recycleDir = Directory(recycleBin);
    //回收站在内部目录，不用考虑使用saf。
    if (!await recycleDir.exists()) {
      await recycleDir.create(recursive: true);
    }
    final FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    if (!await fileSystemOperator.exist(path)) {
      debugPrint("文件不存在: $path");
      return Constant.moveToRecycleBinFail;
    }
    String baseName = await fileSystemOperator.name(path);
    var symbolPosition = baseName.indexOf(".");
    if (symbolPosition > -1) {
      baseName = baseName.substring(0, symbolPosition);
    }
    var fileName = Uuid().v4().replaceAll("-", "");
    final recycleBinPath = p.join(recycleBin, fileName);
    var totalCount = 1;
    try {
      if (await fileSystemOperator.isDir(path)) {
        totalCount = await _countFilesInDirectory(path, onProgress: onProgress);
        if (totalCount == Constant.moveToRecycleBinCancel) {
          return Constant.moveToRecycleBinCancel;
        }
        int count = 0;
        bool continueMove = true;
        await fileSystemOperator.list(path, (entity) async {
          if (!await fileSystemOperator.isDir(entity)) {
            count++;
            if (onProgress != null) {
              continueMove = await onProgress(
                await fileSystemOperator.name(entity),
                count,
                totalCount,
                Constant.moveToRecycleBinStatusCopy,
              );
              if (!continueMove) {
                return true;
              }
            }
            //不应该使用saf。
            var relativePath = await fileSystemOperator.relative(entity, path);
            var destination = p.join(recycleBinPath, relativePath);
            var destDir = Directory(p.dirname(destination));
            if (!await destDir.exists()) {
              await destDir.create(recursive: true);
            }
            await fileSystemOperator.copyToPath(entity, destination);
          }
          return false;
        }, recursive: true);
        if (!continueMove) {
          return Constant.moveToRecycleBinCancel;
        }
        if (onProgress != null) {
          bool continueMove = await onProgress(
            "",
            count,
            totalCount,
            Constant.moveToRecycleBinStatusDelete,
          );
          if (!continueMove) {
            return Constant.moveToRecycleBinCancel;
          }
        }
        await fileSystemOperator.delete(path, recursive: true);
      } else {
        if (onProgress != null) {
          bool continueMove = await onProgress(
            p.basename(path),
            0,
            1,
            Constant.moveToRecycleBinStatusScan,
          );
          if (!continueMove) {
            return Constant.moveToRecycleBinCancel;
          }
        }
        await fileSystemOperator.copyToPath(path, recycleBinPath);
        if (onProgress != null) {
          bool continueMove = await onProgress(
            p.basename(path),
            1,
            1,
            Constant.moveToRecycleBinStatusDelete,
          );
          if (!continueMove) {
            return Constant.moveToRecycleBinCancel;
          }
        }
        await fileSystemOperator.delete(path, recursive: false);
      }
      final RecycleBinItem recycleBinItem = RecycleBinItem();
      recycleBinItem.name = baseName;
      recycleBinItem.path = path;
      recycleBinItem.recycleBinPath = recycleBinPath;
      recycleBinItem.count = totalCount;
      _recycleBinList.add(recycleBinItem);
      await saveRecycleBinList();
      return Constant.moveToRecycleBinSuccess;
    } catch (e) {
      debugPrint("移动失败: $e");
      return Constant.moveToRecycleBinFail;
    }
  }

  static Widget getHighlightWidget(
    String title,
    String subTitle,
    String buttonText,
    VoidCallback? onPressed,
  ) {
    return Card.filled(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subTitle),
        trailing: TextButton(onPressed: onPressed, child: Text(buttonText)),
      ),
    );
  }

  //统计文件数量，如果取消返回-1
  static Future<int> _countFilesInDirectory(
    String dir, {
    Future<bool> Function(String path, int current, int total, int status)?
    onProgress,
  }) async {
    int count = 0;
    FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    bool continueMove = true;
    await fileSystemOperator.list(dir, (url) async {
      if (!await fileSystemOperator.isDir(url)) {
        count++;
        if (onProgress != null) {
          continueMove = await onProgress(
            url,
            0,
            count,
            Constant.moveToRecycleBinStatusScan,
          );
        }
      }
      return !continueMove;
    }, recursive: true);
    if (!continueMove) {
      return Constant.moveToRecycleBinCancel;
    }
    return count;
  }

  //获取获取某个节的名字，传入[code]返回code，传入[happy_1]返回happy_1
  static String getSection(String section) {
    if (section.startsWith("[") && section.endsWith("]")) {
      return section.substring(1, section.length - 1);
    }
    return section;
  }

  //获取某个节的前缀名称，传入[code]返回code，传入[happy_1]返回happy
  static String getSectionPrefix(String section) {
    var sectionName = getSection(section);
    var index = sectionName.lastIndexOf("_");
    if (index > -1) {
      return sectionName.substring(0, index);
    }
    return sectionName;
  }

  static String getSectionSuffix(String section) {
    var sectionName = getSection(section);
    var index = sectionName.lastIndexOf("_");
    if (index > -1 && index < sectionName.length - 1) {
      return sectionName.substring(index + 1);
    }
    return '';
  }

  static String getLanguage(BuildContext context) {
    return Provider.of<LocaleManager>(
      context,
      listen: false,
    ).locale.languageCode;
  }

  static Future<String?> getUserHomeDirectory() async {
    if (Platform.isLinux) {
      return '/home/${Platform.environment['USER']}';
    } else if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['HOMEPATH'];
    } else if (Platform.isAndroid) {
      var directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else {
      return "";
    }
  }
}

///持久化存储
class HiveHelper {
  static late Box _box;
  static String modPath = "modPath";
  static String steamModPath = "steamModPath";
  static String showSteamMod = "showSteamMod";
  static String runedGuide = "runedGuide";
  static String dynamicColorEnabled = "dynamicColorEnabled";
  static String seedColor = "seedColor";
  static String darkMode = "darkMode";
  static String language = "language";
  static String automaticIndexConstruction = "automaticIndexConstruction";
  static String toggleLineNumber = "toggleLineNumber";
  static String displayOperationOptions = "displayOperationOptions";
  static String autoSave = "autoSave";
  static String config = "config";
  static const String includePreRelease = "include_pre_release";
  static const String deleteOriginalFileAfterDecompression =
      "delete_original_file_after_decompression";

  //是否在创建mod后打开工作区(0为否，1为是，2为询问)
  static String openWorkspaceAfterCreateMod = "openWorkspaceAfterCreateMod";
  static String readMagicNumberOfFiles = "readMagicNumberOfFiles";

  //用户要为哪个版本的游戏制作Mod？（假设目标版本为2,那么用户就无法使用大于2版本的相关代码，反编译mod时会将大于2的代码标记为不可用。）
  static String targetGameVersion = "targetGameVersion";

  //归档文件加载限制（字节）
  static String archivedFileLoadingLimit = "archivedFileLoadingLimit";

  //初始化设置信息
  static init(String dataPath) async {
    _box = await Hive.openBox("preferences", path: dataPath);
    if (!_box.containsKey(openWorkspaceAfterCreateMod)) {
      _box.put(openWorkspaceAfterCreateMod, Constant.openWorkSpaceAsk);
    }
    if (!_box.containsKey(darkMode)) {
      //设置为跟随系统
      _box.put(darkMode, Constant.darkModeFollowSystem);
    }
    if (!_box.containsKey(automaticIndexConstruction)) {
      _box.put(automaticIndexConstruction, !Platform.isAndroid);
    }
    if (!_box.containsKey(autoSave)) {
      _box.put(autoSave, true);
    }
    if (!_box.containsKey(archivedFileLoadingLimit)) {
      //默认1MB
      _box.put(
        archivedFileLoadingLimit,
        Constant.defaultArchivedFileLoadingLimit,
      );
    }
    if (_box.containsKey(readMagicNumberOfFiles)) {
      GlobalDepend.readMagicNumberOfFiles = get(readMagicNumberOfFiles);
    }
    await _box.flush();
  }

  static put(dynamic key, dynamic value) async {
    await _box.put(key, value);
    await _box.flush();
  }

  static delete(dynamic key) {
    _box.delete(key);
  }

  static getKeys() {
    return _box.keys;
  }

  static getValues() {
    return _box.values;
  }

  static containsKey(dynamic key) {
    return _box.containsKey(key);
  }

  static get(dynamic key, {dynamic defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }
}
