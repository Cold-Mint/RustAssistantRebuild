import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/file_type_checker.dart';
import 'package:rust_assistant/global_depend.dart';

class FileReference {
  late String data;
  late String path;
  late bool exist;
  late int fileType;
  late String? extra;

  static Future<FileReference?> fromData(
    String sourceFilePath,
    String modPath,
    String? data,
    String? extra,
  ) async {
    if (data == null) {
      return null;
    }
    if (data.isEmpty) {
      return null;
    }
    var dataUpperCase = data.toUpperCase();
    if (dataUpperCase == Constant.none ||
        dataUpperCase == Constant.auto ||
        dataUpperCase == Constant.autoAnimated) {
      return null;
    }
    final String absolutePath = GlobalDepend.switchToAbsolutePath(
      modPath,
      sourceFilePath,
      data,
    );
    if (CodeDataBase.getAssetsPathType(data) != Constant.assetsPathTypeNone) {
      final FileReference fileReference = FileReference();
      fileReference.path = absolutePath;
      fileReference.exist = CodeDataBase.getAssetsExist(data);
      fileReference.fileType = FileTypeChecker.FileTypeImage;
      fileReference.data = data;
      return fileReference;
    }

    final bool exist = await GlobalDepend.getFileSystemOperator().exist(
      absolutePath,
    );
    final FileReference fileReference = FileReference();
    fileReference.path = absolutePath;
    fileReference.exist = exist;
    if (exist) {
      fileReference.fileType = FileTypeChecker.getFileType(
        absolutePath,
        fileHeader: await FileTypeChecker.readFileHeader(absolutePath),
      );
    } else {
      fileReference.fileType = FileTypeChecker.FileTypeUnknown;
    }

    fileReference.data = data;
    fileReference.extra = extra;
    return fileReference;
  }
}
