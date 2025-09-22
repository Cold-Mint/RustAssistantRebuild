import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/pages/built_in_file_selector_page.dart';
import 'package:path/path.dart' as p;

// 文件系统操作的抽象接口
abstract class FileSystemOperator {
  // 判断文件或文件夹是否存在
  Future<bool> exist(String uri);

  //创建目录
  Future<bool> mkdir(String uri, String name);

  //读取文件以文本的方式
  Future<String?> readAsString(String uri);

  Future<Uint8List?> readAsBytes(String uri, {int? start, int? count});

  Future<bool> checkFolderAvailable(String uri);

  //写文件，如果内容为空，那么仅创建文件，
  Future<void> writeFile(String uri, String name, String? content);

  //获取文件或文件夹的名称
  Future<String> name(String uri);

  //获取某个目录下的文件或文件夹 callBack如果返回true那么将终止循环
  Future list(
    String uri,
    Future<bool> Function(String) callBack, {
    bool recursive = false,
  });

  String join(String uri, String name);
  void rename(String oldUri, String newUri);

  //判断给定的uri是否为文件夹
  Future<bool> isDir(String uri);

  //选择目录
  Future<String?> pickDirectory(BuildContext context);

  Future<List<String>?> pickFiles(BuildContext context, String? initialUri);

  //获取某个路径的相对路径
  Future<String> relative(String uri, String from);

  //将文件复制到某个路径下（必须是路径）
  Future<void> copyToPath(String uri, String destination);

  //删除
  Future<void> delete(String uri, {bool recursive = false});

  //获取文件夹路径
  Future<String> dirname(String uri);

  Future<int> size(String uri);
}

// 适用于非安卓的文件操作实现（本地文件系统）
class LocalFileOperator extends FileSystemOperator {
  @override
  Future<bool> exist(String uri) async {
    return await FileSystemEntity.type(uri) != FileSystemEntityType.notFound;
  }

  @override
  Future<bool> mkdir(String uri, String name) async {
    try {
      var dir = Directory(p.join(uri, name));
      await dir.create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> readAsString(String uri) async {
    var file = File(uri);
    if (!await file.exists()) {
      return null;
    }
    try {
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> name(String uri) async {
    return p.basename(uri);
  }

  @override
  Future<bool> isDir(String uri) {
    return Directory(uri).exists();
  }

  @override
  Future list(
    String uri,
    Future<bool> Function(String p1) callBack, {
    bool recursive = false,
  }) async {
    if (!await isDir(uri)) {
      return null;
    }
    Directory directory = Directory(uri);
    if (!await directory.exists()) {
      return null;
    }
    var list = directory.listSync(recursive: recursive);
    for (var value in list) {
      if (await callBack.call(value.path)) {
        return;
      }
    }
  }

  @override
  Future<void> writeFile(String uri, String name, String? content) async {
    File file = File(p.join(uri, name));
    await file.create(recursive: true);
    if (content != null) {
      file.writeAsString(content);
    }
  }

  @override
  Future<String?> pickDirectory(BuildContext context) async {
    if (Platform.isAndroid) {
      var androidChannel = MethodChannel(Constant.androidChannel);
      final String externalStoragePath = await androidChannel.invokeMethod(
        Constant.externalStoragePath,
      );
      if (!context.mounted) {
        return null;
      }
      return await showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return BuiltInFileSelectorPage(
            rootPath: externalStoragePath,
            selectFile: false,
            checkBoxMode: Constant.checkBoxModeNone,
            maxSelectCount: 1,
            selectFileType: FileTypeChecker.FileTypeAll,
          );
        },
      );
    }
    return await FilePicker.platform.getDirectoryPath();
  }

  @override
  Future<bool> checkFolderAvailable(String uri) async {
    return await Directory(uri).exists();
  }

  @override
  String join(String uri, String name) {
    return p.join(uri, name);
  }

  @override
  Future<String> relative(String path, String from) async {
    return p.relative(path, from: from);
  }

  @override
  Future<void> delete(String uri, {bool recursive = false}) {
    return File(uri).delete(recursive: true);
  }

  @override
  Future<void> copyToPath(String uri, String destination) {
    return File(uri).copy(destination);
  }

  @override
  Future<String> dirname(String uri) async {
    return p.dirname(uri);
  }

  @override
  Future<Uint8List?> readAsBytes(String uri, {int? start, int? count}) async {
    final file = File(uri);
    if (!await file.exists()) return null;
    final raf = await file.open();

    // 计算读取起始位置
    int startIndex = start ?? 0;
    if (startIndex < 0) startIndex = 0;

    // 文件长度
    final fileLength = await file.length();
    if (startIndex > fileLength) {
      await raf.close();
      return Uint8List(0); // 超出文件长度，返回空
    }

    // 计算读取长度
    int readLength = count ?? (fileLength - startIndex);
    if (readLength < 0) readLength = 0;
    if (startIndex + readLength > fileLength) {
      readLength = fileLength - startIndex;
    }

    // 定位到start位置
    await raf.setPosition(startIndex);

    // 读取指定长度数据
    final bytes = await raf.read(readLength);

    await raf.close();

    return bytes;
  }

  @override
  Future<List<String>?> pickFiles(
    BuildContext context,
    String? initialUri,
  ) async {
    if (Platform.isAndroid) {
      var androidChannel = MethodChannel(Constant.androidChannel);
      final String externalStoragePath = await androidChannel.invokeMethod(
        Constant.externalStoragePath,
      );
      if (!context.mounted) {
        return null;
      }
      return await showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return BuiltInFileSelectorPage(
            rootPath: externalStoragePath,
            selectFile: true,
            checkBoxMode: Constant.checkBoxModeFile,
            maxSelectCount: Constant.maxSelectCountUnlimited,
            selectFileType: FileTypeChecker.FileTypeAll,
          );
        },
      );
    }
    var filePicker = await FilePicker.platform.pickFiles();
    var files = filePicker?.files;
    if (files == null) {
      return null;
    }
    var result = List<String>.empty(growable: true);
    for (var value in files) {
      var path = value.path;
      if (path == null) {
        continue;
      }
      result.add(path);
    }
    return result;
  }

  @override
  Future<int> size(String uri) async {
    if (await isDir(uri)) {
      return 0;
    }
    return File(uri).length();
  }

  @override
  void rename(String oldUri, String newUri) {
    final src = FileSystemEntity.typeSync(oldUri);
    switch (src) {
      case FileSystemEntityType.file:
        File(oldUri).renameSync(newUri);
        break;
      case FileSystemEntityType.directory:
        Directory(oldUri).renameSync(newUri);
        break;
      default:
        throw PathNotFoundException(
          oldUri,
          const OSError('No such file or directory'),
        );
    }
  }
}

//适用于压缩文件的文件操作实现，直接操作压缩包。
class ZipFileOperator extends FileSystemOperator {
  Archive? _archive;

  void decodeBytes(List<int> bytes) {
    _archive = ZipDecoder().decodeBytes(bytes);
  }

  void decodeStream(InputStream input) {
    _archive = ZipDecoder().decodeStream(input);
  }

  @override
  Future<bool> exist(String uri) async {
    if (_archive == null) {
      return false;
    }
    return _archive?.find(uri) != null;
  }

  @override
  Future<bool> mkdir(String uri, String name) async {
    if (_archive == null) {
      return false;
    }
    var path = p.join(uri, name);
    _archive?.add(ArchiveFile.directory(path));
    return true;
  }

  @override
  Future<String?> readAsString(String uri) async {
    var archiveFile = _archive?.find(uri);
    if (archiveFile == null) {
      return null;
    }
    Uint8List? uint8list = archiveFile.readBytes();
    if (uint8list == null) {
      return null;
    }
    return utf8.decode(uint8list);
  }

  @override
  Future<String> name(String uri) async {
    return p.basename(uri);
  }

  @override
  Future<bool> isDir(String uri) async {
    var archiveFile = _archive?.find(uri);
    if (archiveFile == null) {
      return false;
    }
    return archiveFile.isDirectory;
  }

  @override
  Future list(
    String uri,
    Future<bool> Function(String p1) callBack, {
    bool recursive = false,
  }) async {
    var archiveFile = _archive?.find(uri);
    if (archiveFile == null) {
      return false;
    }
    if (!archiveFile.isDirectory) {
      return;
    }
    List<ArchiveFile>? files = _archive?.files;
    if (files == null) {
      return;
    }
    for (var value in files) {
      if (recursive) {
        if (await callBack.call(value.name)) {
          return;
        }
        continue;
      }
      if (value.name.startsWith(uri)) {
        if (await callBack.call(value.name)) {
          return;
        }
      }
    }
  }

  @override
  Future<String> dirname(String uri) async {
    return p.dirname(uri);
  }

  @override
  Future<void> writeFile(String uri, String name, String? content) async {
    if (_archive == null) {
      return;
    }
    _archive?.add(ArchiveFile.string(p.join(uri, name), content ?? ""));
  }

  @override
  Future<String?> pickDirectory(BuildContext context) async {
    //不能在压缩包文件操作内调用选择新目录
    return null;
  }

  @override
  Future<bool> checkFolderAvailable(String uri) {
    return isDir(uri);
  }

  @override
  String join(String uri, String name) {
    return p.join(uri, name);
  }

  @override
  Future<String> relative(String path, String from) async {
    return p.relative(path, from: from);
  }

  @override
  Future<void> delete(String uri, {bool recursive = false}) async {
    if (_archive == null) {
      return;
    }
    for (final entry in _archive!) {
      if (entry.name.startsWith(uri)) {
        _archive!.removeFile(entry);
      }
    }
  }

  @override
  Future<void> copyToPath(String uri, String destination) async {
    for (final entry in _archive!) {
      if (entry.name.startsWith(uri) && entry.isFile) {
        final fileBytes = entry.readBytes();
        File(destination)
          ..createSync(recursive: true)
          ..writeAsBytes(fileBytes as List<int>);
      }
    }
  }

  @override
  Future<Uint8List?> readAsBytes(String uri, {int? start, int? count}) async {
    var archiveFile = _archive?.find(uri);
    if (archiveFile == null) {
      return null;
    }
    Uint8List? fullBytes = archiveFile.readBytes();

    if (fullBytes == null) {
      return null;
    }
    // 如果没有指定截取，返回全部
    if (start == null && count == null) {
      return fullBytes;
    }

    // 计算截取起始位置
    int startIndex = start ?? 0;
    if (startIndex < 0) startIndex = 0;
    if (startIndex > fullBytes.length) return Uint8List(0);

    // 计算截取长度
    int length = count ?? (fullBytes.length - startIndex);
    if (length < 0) length = 0;
    if (startIndex + length > fullBytes.length) {
      length = fullBytes.length - startIndex;
    }

    return fullBytes.sublist(startIndex, startIndex + length);
  }

  @override
  Future<List<String>?> pickFiles(
    BuildContext context,
    String? initialUri,
  ) async {
    return null;
  }

  @override
  Future<int> size(String uri) async {
    if (await isDir(uri)) {
      return 0;
    }
    return File(uri).length();
  }

  @override
  void rename(String oldUri, String newUri) {}
}
