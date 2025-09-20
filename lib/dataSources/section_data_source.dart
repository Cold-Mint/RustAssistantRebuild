import '../databeans/section_info.dart';
import '../search_multiple_selection_dialog.dart';

class SectionDataSource extends DataSource<SectionInfo> {
  SectionDataSource(super.dialogTitle, super.searchHint, super.confirmButtonText);

  @override
  List<SectionInfo> generateFilteredList(String keyword, bool hideExisting) {
    final List<SectionInfo> filteredByExist = hideExisting
        ? allList
              .where(
                (sectionInfo) =>
                    sectionInfo.hasName == true ||
                    !existedList.contains(sectionInfo),
              )
              .toList()
        : allList;
    var searchKeywordLowCase = keyword.toLowerCase();
    return keyword.isEmpty
        ? filteredByExist
        : filteredByExist.where((sectionInfo) {
            var translate = sectionInfo.translate;
            if (translate != null &&
                translate.toLowerCase().contains(searchKeywordLowCase)) {
              return true;
            }
            var section = sectionInfo.section;
            if (section != null &&
                section.toLowerCase().contains(searchKeywordLowCase)) {
              return true;
            }
            return false;
          }).toList();
  }

  @override
  String? getSubTitle(SectionInfo item) {
    return null;
  }

  @override
  String getTitle(SectionInfo item) {
    StringBuffer buffer = StringBuffer();
    if (item.translate != null) {
      buffer.write(item.translate);
    }
    if (item.section != null) {
      buffer.write('(');
      buffer.write(item.section);
      buffer.write(')');
    }
    return buffer.toString();
  }
}
