import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rust_assistant/constant.dart';
import 'package:rust_assistant/databeans/unit_ref.dart';
import 'package:rust_assistant/databeans/code.dart';
import 'package:rust_assistant/databeans/enum_data.dart';
import 'package:rust_assistant/databeans/logical_boolean.dart';
import 'package:rust_assistant/databeans/section_info.dart';
import 'package:rust_assistant/global_depend.dart';

import 'dataSources/code_data_source.dart';
import 'databeans/code_info.dart';
import 'databeans/game_version.dart';
import 'databeans/language_code.dart';
import 'databeans/logical_boolean_translate.dart';
import 'databeans/unit_template.dart';

class CodeDataBase {
  static final List<GameVersion> _gameVersion = List.empty(growable: true);
  static final List<SectionInfo> _sectionInfo = List.empty(growable: true);
  static final List<Code> _code = List.empty(growable: true);
  static final List<CodeInfo> _codeInfo = List.empty(growable: true);
  static final List<LogicalBoolean> _logicalBoolean = List.empty(
    growable: true,
  );
  static final Map<String, EnumData> _enumData = {};
  static UnitTemplate? _unitTemplate;
  static final List<LanguageCode> _languageCode = List.empty(growable: true);
  static final List<LogicalBooleanTranslate> _logicalBooleanTranslate =
      List.empty(growable: true);
  static bool haveGenerateCode = false;
  static int _targetVersion = 0;
  static int _gameDataVersion = 1;
  static final List<int> _gameDataArray = [1, 4, 8];
  static List<String> coreRes = List.empty(growable: true);
  static List<String> sharedRes = List.empty(growable: true);
  static List<UnitRef> builtInUnit = List.empty(growable: true);

  static List<LogicalBoolean> getLogicalBooleanList() {
    return _logicalBoolean;
  }

  static EnumData? getEnumData(String id) {
    return _enumData[id];
  }

  static LogicalBoolean? matchLogicalBooleanByContent(String item) {
    for (var value in _logicalBoolean) {
      String? rule = value.rule;
      if (rule == null) {
        continue;
      }
      if (RegExp(rule).hasMatch(item)) {
        return value;
      }
    }
    return null;
  }

  static SectionInfo? findSectionInfo(String fullSectionName) {
    for (var value in _sectionInfo) {
      String? rule = value.rule;
      if (rule == null) {
        continue;
      }
      if (RegExp(rule).hasMatch(fullSectionName)) {
        return value;
      }
    }
    return null;
  }

  static LogicalBoolean? findLogicalBooleanByName(String name) {
    for (var value in _logicalBoolean) {
      var finalName = value.name;
      if (finalName == null) {
        continue;
      }
      if (finalName.toLowerCase().startsWith(name.toLowerCase())) {
        return value;
      }
    }
    return null;
  }

  static LogicalBooleanTranslate? matchLogicalBooleanTranslateByContent(
    String content,
  ) {
    for (var value in _logicalBooleanTranslate) {
      String? rule = value.rule;
      if (rule == null) {
        continue;
      }
      if (RegExp(rule).hasMatch(content)) {
        return value;
      }
    }
    return null;
  }

  static LogicalBooleanTranslate? findLogicalBooleanTranslateByRule(
    String rule,
  ) {
    for (var value in _logicalBooleanTranslate) {
      String? rule1 = value.rule;
      if (rule1 == null) {
        continue;
      }
      if (rule == rule1) {
        return value;
      }
    }
    return null;
  }

  //根据key获取代码(key和section)section要前缀
  static Code? getCode(String key, String sectionPrefix) {
    for (var code in _code) {
      var codeRule = code.code;
      var sectionRule = code.section;
      var minVersion = code.minVersion ?? 1;
      if (minVersion > _targetVersion) {
        continue;
      }
      if (codeRule == null || sectionRule == null) {
        continue;
      }
      if (!RegExp(sectionRule).hasMatch(sectionPrefix)) {
        continue;
      }
      if (RegExp(codeRule).hasMatch(key)) {
        return code;
      }
    }
    return null;
  }

  static void parseMixedCodeList(
    List<MixedCode> mixedCodeList, {
    Function(Code, CodeInfo)? onParsed,
  }) {
    for (MixedCode mixedCode in mixedCodeList) {
      onParsed?.call(mixedCode.code, mixedCode.codeInfo);
    }
  }

  static List<GameVersion> getGameVersion() {
    return _gameVersion;
  }

  //根据key获取代码(key和section)section要前缀
  static CodeInfo? getCodeInfo(String key, String sectionPrefix) {
    for (var code in _codeInfo) {
      var codeRule = code.code;
      var sectionRule = code.section;
      if (codeRule == null || sectionRule == null) {
        continue;
      }
      if (!RegExp(sectionRule).hasMatch(sectionPrefix)) {
        continue;
      }
      if (RegExp(codeRule).hasMatch(key)) {
        var rule = code.rule;
        if (rule != null) {
          final match = RegExp(rule).firstMatch(key);
          if (match != null) {
            CodeInfo codeInfoCopy = CodeInfo.fromJson(code.toJson());
            for (int i = 1; i <= match.groupCount; i++) {
              codeInfoCopy.translate = code.translate!.replaceAll(
                "{$i}",
                match.group(i)!,
              );
            }
            return codeInfoCopy;
          }
        }
        return code;
      }
    }
    return null;
  }

  //加载游戏版本信息
  static Future<void> loadGameVersion() async {
    _gameVersion.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/code_data/game_versions.json'),
    );
    for (var item in jsonData) {
      _gameVersion.add(GameVersion.fromJson(item));
    }
  }

  static Future<void> loadLogicalBoolean() async {
    _logicalBoolean.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/code_data/logical_boolean.json'),
    );
    for (var item in jsonData) {
      _logicalBoolean.add(LogicalBoolean.fromJson(item));
    }
  }

  static Future<void> loadLogicalBooleanTranslate(String language) async {
    _logicalBooleanTranslate.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString(
        'assets/code_data/logical_boolean_info_$language.json',
      ),
    );
    for (var item in jsonData) {
      _logicalBooleanTranslate.add(LogicalBooleanTranslate.fromJson(item));
    }
  }

  //加载完成数据后需要由生成arm和hiddenAction节的代码
  static Future<void> generateCodeIntoMemory() async {
    //生成core的代码
    if (!haveGenerateCode) {
      var generateCode = List<Code>.empty(growable: true);
      for (Code code in _code) {
        var section = code.section;
        if (section == null) {
          continue;
        }
        if (section == "leg" || section == "action") {
          final Code newCode = Code();
          newCode.code = code.code;
          newCode.minVersion = code.minVersion;
          newCode.maxVersion = code.maxVersion;
          newCode.interpreter = code.interpreter;
          newCode.fileName = code.fileName;
          newCode.defaultKey = code.defaultKey;
          newCode.defaultValue = code.defaultValue;
          newCode.allowRepetition = code.allowRepetition;
          if (section == "leg") {
            newCode.section = "arm";
          } else {
            newCode.section = "hiddenAction";
          }
          generateCode.add(newCode);
        }
      }
      _code.addAll(generateCode);
      if (HiveHelper.containsKey(HiveHelper.targetGameVersion)) {
        await setTargetVersion(
          HiveHelper.get(
            HiveHelper.language,
            defaultValue: Constant.defaultLanguage,
          ),
          HiveHelper.get(HiveHelper.targetGameVersion),
        );
      } else {
        var gameVersion = _gameVersion.where((g) => g.visible == true).last;
        HiveHelper.put(HiveHelper.targetGameVersion, gameVersion.versionCode);
        await setTargetVersion(
          HiveHelper.get(
            HiveHelper.language,
            defaultValue: Constant.defaultLanguage,
          ),
          gameVersion.hashCode,
        );
      }
      haveGenerateCode = true;
    }

    var generateCodeInfo = List<CodeInfo>.empty(growable: true);
    for (CodeInfo codeInfo in _codeInfo) {
      var section = codeInfo.section;
      if (section == null) {
        continue;
      }
      if (section == "leg" || section == "action") {
        final CodeInfo newCodeInfo = CodeInfo();
        newCodeInfo.code = codeInfo.code;
        newCodeInfo.translate = codeInfo.translate;
        newCodeInfo.description = codeInfo.description;
        if (section == "leg") {
          newCodeInfo.section = "arm";
        } else {
          newCodeInfo.section = "hiddenAction";
        }
        generateCodeInfo.add(newCodeInfo);
      }
    }
    _codeInfo.addAll(generateCodeInfo);
  }

  static Future<void> setTargetVersion(
    String language,
    int targetVersion,
  ) async {
    _targetVersion = targetVersion;
    var gameDataVersion = 0;
    for (var value in _gameDataArray) {
      if (value > targetVersion) {
        break;
      }
      gameDataVersion = value;
    }
    _gameDataVersion = gameDataVersion;
    final List<dynamic> coreResJsonData = json.decode(
      await rootBundle.loadString(
        'assets/game_res/$gameDataVersion/core_res.json',
      ),
    );
    coreRes.clear();
    for (var item in coreResJsonData) {
      coreRes.add(item);
    }
    final List<dynamic> sharedResJsonData = json.decode(
      await rootBundle.loadString(
        'assets/game_res/$gameDataVersion/shared_res.json',
      ),
    );
    sharedRes.clear();
    for (var item in sharedResJsonData) {
      sharedRes.add(item);
    }
    loadUnits(language);
  }

  static bool getAssetsExist(String data) {
    var lowCaseData = data.toLowerCase();
    if (lowCaseData.startsWith(Constant.pathPrefixShared)) {
      lowCaseData = lowCaseData.substring(Constant.pathPrefixShared.length);
      if (lowCaseData.startsWith("/") || lowCaseData.startsWith("\\")) {
        lowCaseData = lowCaseData.substring(1);
      }
      for (var value in sharedRes) {
        if (value.toLowerCase() == lowCaseData) {
          return true;
        }
      }
      return false;
    }
    if (lowCaseData.startsWith(Constant.pathPrefixCore)) {
      lowCaseData = lowCaseData.substring(Constant.pathPrefixCore.length);
      if (lowCaseData.startsWith("/") || lowCaseData.startsWith("\\")) {
        lowCaseData = lowCaseData.substring(1);
      }
      for (var value in coreRes) {
        if (value.toLowerCase() == lowCaseData) {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  static int getAssetsPathType(String data) {
    var lowCaseData = data.toLowerCase();
    if (lowCaseData.startsWith(Constant.pathPrefixShared)) {
      return Constant.assetsPathTypeShared;
    }
    if (lowCaseData.startsWith(Constant.pathPrefixCore)) {
      return Constant.assetsPathTypeCore;
    }
    return Constant.assetsPathTypeNone;
  }

  static String toAssetsPath(String path, int type) {
    if (type == Constant.assetsPathTypeShared) {
      return Constant.pathPrefixShared.toUpperCase() + path;
    }
    if (type == Constant.assetsPathTypeCore) {
      return Constant.pathPrefixCore.toUpperCase() + path;
    }
    return path;
  }

  static String getCorePath(String path) {
    return 'assets/game_res/$_gameDataVersion/units/$path';
  }

  static String getSharedPath(String path) {
    return 'assets/game_res/$_gameDataVersion/units/shared/$path';
  }

  static Future<void> loadUnits(String language) async {
    final List<dynamic> dexUnits = json.decode(
      await rootBundle.loadString('assets/game_res/dex_units_$language.json'),
    );
    final List<dynamic> units = json.decode(
      await rootBundle.loadString(
        'assets/game_res/$_gameDataVersion/units_$language.json',
      ),
    );
    builtInUnit.clear();
    for (var item in dexUnits) {
      builtInUnit.add(UnitRef.fromJson(item));
    }
    for (var item in units) {
      builtInUnit.add(UnitRef.fromJson(item));
    }
  }

  static Future<void> loadEnumData(String language) async {
    _enumData.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/code_data/enum_$language.json'),
    );
    for (var item in jsonData) {
      var enumObject = EnumData.fromJson(item);
      if (enumObject.id != null) {
        _enumData[enumObject.id!] = enumObject;
      }
    }
  }

  static UnitTemplate? getUnitsTemplate() {
    return _unitTemplate;
  }

  static Future<void> loadUnitsTemplate(String language) async {
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/units_template/index.json'),
    );
    for (var item in jsonData) {
      var unitTemplate = UnitTemplate.fromJson(item);
      if (unitTemplate.language == language) {
        _unitTemplate = unitTemplate;
        return;
      }
    }
    _unitTemplate = null;
  }

  static Future<void> loadSectionInfo(String language) async {
    _sectionInfo.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString(
        'assets/code_data/section_info_$language.json',
      ),
    );
    for (var item in jsonData) {
      _sectionInfo.add(SectionInfo.fromJson(item));
    }
  }

  static final Map<String, Map<String, bool>> _regexMatchCache = {};

  //获取某个节内的代码信息
  static List<CodeInfo> getCodeInfoInSection(String prefixSection) {
    List<CodeInfo> codeInfoList = List.empty(growable: true);
    final cache = _regexMatchCache.putIfAbsent(
      prefixSection,
      () => <String, bool>{},
    );

    for (var value in _codeInfo) {
      final section = value.section;
      if (section == null) continue;
      bool? isMatch = cache[section];
      if (isMatch == null) {
        isMatch = RegExp(section).hasMatch(prefixSection);
        cache[section] = isMatch;
      }

      if (isMatch) {
        codeInfoList.add(value);
      }
    }

    return codeInfoList;
  }

  static List<SectionInfo> getSectionInfoList() {
    return _sectionInfo;
  }

  static List<SectionInfo> getSectionInfoListByFileName(String inputFileName) {
    var result = List<SectionInfo>.empty(growable: true);
    for (var value in _sectionInfo) {
      var fileName = value.fileName;
      if (fileName == null) {
        continue;
      }

      if (RegExp(fileName).hasMatch(inputFileName)) {
        result.add(value);
      }
    }
    return result;
  }

  static Code? getCodeObjectByCode(String code) {
    for (var value in _code) {
      var minVersion = value.minVersion ?? 1;
      if (minVersion > _targetVersion) {
        continue;
      }
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }

  static List<LanguageCode> getLanguageCodeList() {
    return _languageCode;
  }

  static String? findLanguageCode(String translate) {
    for (var value in _languageCode) {
      if (value.translate == translate) {
        return value.code;
      }
    }
    return null;
  }

  //查找语言代码对应的翻译
  static String? findLanguageCodeTranslate(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }
    var codeLowerCase = code.toLowerCase();
    for (var value in _languageCode) {
      if (value.code == codeLowerCase) {
        return value.translate;
      }
    }
    return null;
  }

  static Future<void> loadLanguageCode(String language) async {
    _languageCode.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString(
        'assets/code_data/language_code_$language.json',
      ),
    );
    for (var item in jsonData) {
      _languageCode.add(LanguageCode.fromJson(item));
    }
  }

  static Future<void> loadCodeInfo(String language) async {
    _codeInfo.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/code_data/code_info_$language.json'),
    );
    for (var item in jsonData) {
      _codeInfo.add(CodeInfo.fromJson(item));
    }
  }

  static Future<void> loadCode() async {
    _code.clear();
    final List<dynamic> jsonData = json.decode(
      await rootBundle.loadString('assets/code_data/codes.json'),
    );
    for (var item in jsonData) {
      _code.add(Code.fromJson(item));
    }
  }
}
