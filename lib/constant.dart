class Constant {
  //认证服务器地址
  static const int responseCodeSuccess = 0;
  static const int responseCodeFail = 1;
  static const String modInfoFileName = "mod-info.txt";
  static const String steamBatFileName = "steam.dat";
  static const String allUnitsTemplate = "all-units.template";
  static const int openWorkSpaceAsk = 2;
  static const int openWorkSpaceAlways = 1;
  static const int openWorkSpaceNever = 0;
  static const int moveToRecycleBinSuccess = 1;
  static const int moveToRecycleBinFail = 0;
  static const int moveToRecycleBinCancel = -1;
  static const int moveToRecycleBinStatusReady = 0;
  static const int moveToRecycleBinStatusScan = 1;
  static const int moveToRecycleBinStatusCopy = 2;
  static const int moveToRecycleBinStatusDelete = 3;
  static const int darkModeFollowSystem = 0;
  static const int darkModeFollowLight = 1;
  static const int darkModeFollowDark = 2;
  static const int checkBoxModeNone = 0;
  static const int checkBoxModeFile = 1;
  static const String defaultLanguage = 'zh';
  static const String currentPathRefresh = "Refresh";
  static const String androidChannel = "Android_Channel";
  static const String flutterChannel = "Flutter_Channel";
  static const String getPersistedUriPermissions = "getPersistedUriPermissions";
  static const String releasePersistableUriPermission =
      "releasePersistableUriPermission";
  static const String checkPermissions = "checkPermissions";
  static const String requestPermissions = "requestPermissions";
  static const String externalStoragePath = "externalStoragePath";
  static const String deleteUnintroducedModPath = "deleteUnintroducedModPath";
  static const String openStoragePermissionSetting =
      "openStoragePermissionSetting";
  static const String none = "NONE";
  static const String auto = "AUTO";
  static const String autoAnimated = "AUTO_ANIMATED";
  static const int maxSelectCountUnlimited = -1;
  static const int assetsPathTypeNone = 1;
  static const int assetsPathTypeCore = 2;
  static const int assetsPathTypeShared = 3;
  static const String pathPrefixRoot = "root:";
  static const String pathPrefixCore = "core:";
  static const String pathPrefixShared = "shared:";
  static const int segmentIndexShared = 3;
  static const int segmentIndexCore = 2;
  static const int segmentIndexFile = 1;
  static const int typeUsedRes = 1;
  static const int typeAllRes = 2;
  static const int importCodeRead = 1;
  static const int importCodeLoading = 2;
  static const int importCodeCompleted = 3;
  static const int defaultArchivedFileLoadingLimit = 1048576;
  static const String recycleBinConfigFile = "recycleBin.json";
  static const int userAgreementDocId = 5;
  static const int privacyPolicyDocId = 6;
}

class GameVersionCode {
  static const int vBefore1_13 = 1;
  static const int v1_13 = 2;
  static const int v1_13_3 = 3;
  static const int v1_14 = 4;
  static const int v1_15 = 5;
  static const int v1_15p9 = 6;
  static const int v1_15p10 = 7;
  static const int v1_15p11 = 8;
  static const int v1_16 = 9;

  //最大值，表示一直可用尚未废弃的
  static const int max = -1;
}
