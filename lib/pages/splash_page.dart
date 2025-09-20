import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/global_depend.dart';
import 'package:rust_assistant/pages/guide_page.dart';

import '../constant.dart';
import '../locale_manager.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashPageState();
  }
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocaleManager>(context, listen: false).loadLocale();
      initTask();
    });
  }

  void initTask() async {
    //todo:checkUpdateFrom Github
    // var temContext = context;
    // //检查更新
    // if (!temContext.mounted) {
    //   return;
    // }
    // bool needUpdate = await GlobalDepend.checkUpdate(temContext, () {
    //   afterCheckUpdate();
    // });
    // if (needUpdate) {
    //   return;
    // }
    afterCheckUpdate();
  }

  void afterCheckUpdate() async {
    var finalContext = context;
    if (finalContext.mounted) {
      await initCodeData(finalContext);
    }
    await GlobalDepend.loadRecycleBinList();
    if (finalContext.mounted) {
      Navigator.pop(finalContext);
      Navigator.push(
        finalContext,
        MaterialPageRoute(
          builder: (context) {
            if (HiveHelper.get(HiveHelper.runedGuide, defaultValue: false)) {
              return HomePage();
            } else {
              return GuidePage();
            }
          },
        ),
      );
    }
  }

  Future initCodeData(BuildContext buildContext) async {
    await CodeDataBase.loadLogicalBoolean();
    await CodeDataBase.loadGameVersion();
    await CodeDataBase.loadCode();
    var finalBuildContext = buildContext;
    if (finalBuildContext.mounted) {
      var language = GlobalDepend.getLanguage(finalBuildContext);
      await CodeDataBase.loadCodeInfo(language);
      await CodeDataBase.loadLanguageCode(language);
      await CodeDataBase.loadSectionInfo(language);
      await CodeDataBase.loadUnitsTemplate(language);
      await CodeDataBase.loadLogicalBooleanTranslate(language);
      await CodeDataBase.loadEnumData(language);
      await CodeDataBase.loadUnits(language);
      await CodeDataBase.generateCodeIntoMemory();
    } else {
      await CodeDataBase.loadCodeInfo(Constant.defaultLanguage);
      await CodeDataBase.loadLanguageCode(Constant.defaultLanguage);
      await CodeDataBase.loadSectionInfo(Constant.defaultLanguage);
      await CodeDataBase.loadUnitsTemplate(Constant.defaultLanguage);
      await CodeDataBase.loadLogicalBooleanTranslate(Constant.defaultLanguage);
      await CodeDataBase.loadEnumData(Constant.defaultLanguage);
      await CodeDataBase.loadUnits(Constant.defaultLanguage);
      await CodeDataBase.generateCodeIntoMemory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
