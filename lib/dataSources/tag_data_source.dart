import '../search_multiple_selection_dialog.dart';

class TagDataSource extends DataSource<String> {
  TagDataSource(super.dialogTitle, super.searchHint, super.confirmButtonText);

  @override
  String? getSubTitle(String item) {
    return null;
  }

  @override
  String getTitle(String item) {
    return item;
  }

  @override
  List<String> generateFilteredList(String keyword, bool hideExisting) {
    final List<String> filteredByExist = hideExisting
        ? allList.where((tag) => !existedList.contains(tag)).toList()
        : allList;
    var searchKeywordLowCase = keyword.toLowerCase();
    return keyword.isEmpty
        ? filteredByExist
        : filteredByExist.where((tag) {
            return tag.toLowerCase().contains(searchKeywordLowCase);
          }).toList();
  }
}
