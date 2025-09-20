import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:rust_assistant/file_operator/file_operator.dart';
import 'package:rust_assistant/global_depend.dart';

class FileTypeChecker {
  //默认读取多少字节（作为文件头）
  static int readByteCount = 16;
  static const FileTypeText = 1;
  static const FileTypeImage = 2;
  static const FileTypeAudio = 3;
  static const FileTypeArchive = 4;
  static const FileTypeUnknown = 5;
  static const FileTypeAll = -1;

  //从指定的文件路径读取文件头。
  static Future<Uint8List?> readFileHeader(String path) async {
    final FileSystemOperator fileSystemOperator =
        GlobalDepend.getFileSystemOperator();
    return await fileSystemOperator.readAsBytes(
      path,
      start: 0,
      count: readByteCount,
    );
  }

  static int _getFileTypeByExtension(String path) {
    String extension = p.extension(path).toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.gif') {
      return FileTypeImage;
    }
    if (extension == '.ogg' ||
        extension == '.mp3' ||
        extension == '.wav' ||
        extension == '.flac') {
      return FileTypeAudio;
    }
    if (extension == '.ini' ||
        extension == '.txt' ||
        extension == '.json' ||
        extension == '.yaml' ||
        extension == '.xml' ||
        extension == '.template') {
      return FileTypeText;
    }
    String fileName = p.basename(path).toLowerCase();
    if (fileName == '.nomedia') {
      return FileTypeText;
    }
    return FileTypeUnknown;
  }

  static int getFileType(String path, {Uint8List? fileHeader}) {
    if (fileHeader == null || fileHeader.isEmpty) {
      // 没有指定文件头，以文件后缀判断。
      return _getFileTypeByExtension(path);
    }
    // 判断图片魔数
    if (fileHeader.length >= 8) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (fileHeader[0] == 0x89 &&
          fileHeader[1] == 0x50 &&
          fileHeader[2] == 0x4E &&
          fileHeader[3] == 0x47 &&
          fileHeader[4] == 0x0D &&
          fileHeader[5] == 0x0A &&
          fileHeader[6] == 0x1A &&
          fileHeader[7] == 0x0A) {
        return FileTypeImage;
      }
    }
    if (fileHeader.length >= 3) {
      // JPEG: FF D8 FF
      if (fileHeader[0] == 0xFF &&
          fileHeader[1] == 0xD8 &&
          fileHeader[2] == 0xFF) {
        return FileTypeImage;
      }
    }
    if (fileHeader.length >= 6) {
      // GIF: 47 49 46 38 37 61 或 47 49 46 38 39 61
      if (fileHeader[0] == 0x47 &&
          fileHeader[1] == 0x49 &&
          fileHeader[2] == 0x46 &&
          fileHeader[3] == 0x38 &&
          (fileHeader[4] == 0x37 || fileHeader[4] == 0x39) &&
          fileHeader[5] == 0x61) {
        return FileTypeImage;
      }
    }

    // 判断音频魔数
    if (fileHeader.length >= 12) {
      // WAV: 52 49 46 46 xx xx xx xx 57 41 56 45
      if (fileHeader[0] == 0x52 &&
          fileHeader[1] == 0x49 &&
          fileHeader[2] == 0x46 &&
          fileHeader[3] == 0x46 &&
          fileHeader[8] == 0x57 &&
          fileHeader[9] == 0x41 &&
          fileHeader[10] == 0x56 &&
          fileHeader[11] == 0x45) {
        return FileTypeAudio;
      }
    }

    // 判断压缩文件魔数
    if (fileHeader.length >= 4) {
      if ((fileHeader[0] == 0x50 &&
              fileHeader[1] == 0x4B &&
              fileHeader[2] == 0x03 &&
              fileHeader[3] == 0x04) ||
          (fileHeader[0] == 0x50 &&
              fileHeader[1] == 0x4B &&
              fileHeader[2] == 0x05 &&
              fileHeader[3] == 0x06) ||
          (fileHeader[0] == 0x50 &&
              fileHeader[1] == 0x4B &&
              fileHeader[2] == 0x07 &&
              fileHeader[3] == 0x08)) {
        return FileTypeArchive;
      }
    }

    if (fileHeader.length >= 4) {
      // OGG: 4F 67 67 53
      if (fileHeader[0] == 0x4F &&
          fileHeader[1] == 0x67 &&
          fileHeader[2] == 0x67 &&
          fileHeader[3] == 0x53) {
        return FileTypeAudio;
      }
    }
    if (fileHeader.length >= 3) {
      // MP3的帧头有很多种可能，这里简单判断常见帧头FF FB或FF F3或FF F2
      if (fileHeader[0] == 0xFF &&
          (fileHeader[1] == 0xFB ||
              fileHeader[1] == 0xF3 ||
              fileHeader[1] == 0xF2)) {
        return FileTypeAudio;
      }
    }
    if (fileHeader.length >= 4) {
      // FLAC: 66 4C 61 43
      if (fileHeader[0] == 0x66 &&
          fileHeader[1] == 0x4C &&
          fileHeader[2] == 0x61 &&
          fileHeader[3] == 0x43) {
        return FileTypeAudio;
      }
    }

    // 判断是否是文本文件（简单判断文件头是否全为可打印ASCII字符或常见控制字符）
    bool isText = true;
    for (var byte in fileHeader) {
      if (byte == 0) {
        // 文件头有空字节，基本不是文本文件
        isText = false;
        break;
      }
      if (byte < 9 || (byte > 13 && byte < 32) || byte > 126) {
        // 非常见的可打印ASCII字符范围之外，认为不是文本
        isText = false;
        break;
      }
    }
    if (isText) {
      return FileTypeText;
    }
    return _getFileTypeByExtension(path);
  }
}
