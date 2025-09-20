import '../databeans/logical_boolean.dart';
import '../databeans/logical_boolean_translate.dart';
import '../search_multiple_selection_dialog.dart';

class LogicBooleanDataSource extends DataSource<MixedLogicalBoolean> {
  LogicBooleanDataSource(super.dialogTitle, super.searchHint, super.confirmButtonText);

  @override
  List<MixedLogicalBoolean> generateFilteredList(
    String keyword,
    bool hideExisting,
  ) {
    var searchKeywordLowCase = keyword.toLowerCase();
    return keyword.isEmpty
        ? allList
        : allList.where((mixedLogicalBoolean) {
            var name = mixedLogicalBoolean.logicalBoolean.name;
            if (name == null) {
              return false;
            }
            bool matchByName = name.toLowerCase().contains(
              searchKeywordLowCase,
            );
            if (matchByName) {
              return true;
            }
            var logicalBooleanTranslate =
                mixedLogicalBoolean.logicalBooleanTranslate;
            if (logicalBooleanTranslate == null) {
              return false;
            }
            var translate = logicalBooleanTranslate.translate;
            if (translate == null) {
              return false;
            }
            var description = logicalBooleanTranslate.description;
            if (description == null) {
              return false;
            }
            return translate.toLowerCase().contains(searchKeywordLowCase) ||
                description.toLowerCase().contains(searchKeywordLowCase);
          }).toList();
  }

  @override
  String? getSubTitle(MixedLogicalBoolean item) {
    return item.logicalBooleanTranslate?.description;
  }

  @override
  String getTitle(MixedLogicalBoolean item) {
    var translate = item.logicalBooleanTranslate;
    var translateName = translate?.translate;
    StringBuffer showName = StringBuffer();
    if (translateName != null && translateName != item.logicalBoolean.name) {
      showName.write(translateName);
      showName.write("(");
      showName.write(item.logicalBoolean.name);
      showName.write(")");
    } else {
      showName.write(item.logicalBoolean.name);
    }
    return showName.toString();
  }
}

//混合逻辑布尔和翻译
class MixedLogicalBoolean {
  final LogicalBoolean logicalBoolean;
  final LogicalBooleanTranslate? logicalBooleanTranslate;

  MixedLogicalBoolean(this.logicalBoolean, this.logicalBooleanTranslate);

  @override
  bool operator ==(Object other) {
    if (other is! MixedLogicalBoolean) {
      return false;
    }
    return logicalBoolean.name == other.logicalBoolean.name;
  }

  @override
  int get hashCode => logicalBoolean.name.hashCode;
}
