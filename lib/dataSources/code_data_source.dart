import 'package:rust_assistant/search_multiple_selection_dialog.dart';

import '../databeans/code.dart';
import '../databeans/code_info.dart';

class CodeDataSource extends DataSource<MixedCode> {
  CodeDataSource(super.dialogTitle, super.searchHint, super.confirmButtonText);

  @override
  List<MixedCode> generateFilteredList(String keyword, bool hideExisting) {
    final List<MixedCode> filteredByExist = hideExisting
        ? allList
              .where(
                (code) =>
                    code.code.allowRepetition == true ||
                    !existedList.contains(code),
              )
              .toList()
        : allList;
    var searchKeywordLowCase = keyword.toLowerCase();
    return keyword.isEmpty
        ? filteredByExist
        : filteredByExist.where((code) {
            var translate = code.codeInfo.translate;
            if (translate != null &&
                translate.toLowerCase().contains(searchKeywordLowCase)) {
              return true;
            }
            var description = code.codeInfo.description;
            if (description != null &&
                description.toLowerCase().contains(searchKeywordLowCase)) {
              return true;
            }
            var defaultKey = code.code.defaultKey;
            if (defaultKey != null &&
                defaultKey.toLowerCase().contains(searchKeywordLowCase)) {
              return true;
            }
            return false;
          }).toList();
  }

  @override
  String getTitle(MixedCode item) {
    StringBuffer buffer = StringBuffer();
    if (item.codeInfo.translate != null) {
      buffer.write(item.codeInfo.translate);
    }
    if (item.code.defaultKey != null &&
        item.code.defaultKey != item.codeInfo.translate) {
      buffer.write('(');
      buffer.write(item.code.defaultKey);
      buffer.write(')');
    }
    return buffer.toString();
  }

  @override
  String? getSubTitle(MixedCode item) {
    return item.codeInfo.description;
  }
}

class MixedCode {
  final CodeInfo codeInfo;
  final Code code;

  @override
  bool operator ==(Object other) {
    if (other is! MixedCode) {
      return false;
    }
    return other.code.code == code.code;
  }

  MixedCode(this.codeInfo, this.code);

  @override
  int get hashCode => code.code.hashCode;
}
