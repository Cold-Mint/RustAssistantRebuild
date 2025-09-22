import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @translator.
  ///
  /// In en, this message translates to:
  /// **'Youdao Translation'**
  String get translator;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Rust Assistant Rebuild'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @readAndAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agreed'**
  String get readAndAgree;

  /// No description provided for @userAgreement.
  ///
  /// In en, this message translates to:
  /// **'UserAgreement'**
  String get userAgreement;

  /// No description provided for @modFolder.
  ///
  /// In en, this message translates to:
  /// **'Mod Folder'**
  String get modFolder;

  /// No description provided for @steamWorkshopFolder.
  ///
  /// In en, this message translates to:
  /// **'Steam Workshop Folder'**
  String get steamWorkshopFolder;

  /// No description provided for @showModFromSteam.
  ///
  /// In en, this message translates to:
  /// **'Show Modules from Steam Workshop'**
  String get showModFromSteam;

  /// No description provided for @restoreToDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Restore to default folder'**
  String get restoreToDefaultFolder;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'PrivacyPolicy'**
  String get privacyPolicy;

  /// No description provided for @mods.
  ///
  /// In en, this message translates to:
  /// **'Mods'**
  String get mods;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @pathConfig.
  ///
  /// In en, this message translates to:
  /// **'Path Configurations'**
  String get pathConfig;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @couldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Could not be loaded'**
  String get couldNotBeLoaded;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @notSupportSteam.
  ///
  /// In en, this message translates to:
  /// **'This platform does not support the display of modules from the Steam Workshop.'**
  String get notSupportSteam;

  /// No description provided for @invalidFolder.
  ///
  /// In en, this message translates to:
  /// **'Invalid folder'**
  String get invalidFolder;

  /// No description provided for @folderDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'This directory does not exist or does not have access rights.'**
  String get folderDoesNotExist;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get none;

  /// No description provided for @openItInTheFileManager.
  ///
  /// In en, this message translates to:
  /// **'Open it in the file manager'**
  String get openItInTheFileManager;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit units'**
  String get editUnit;

  /// No description provided for @fail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get fail;

  /// No description provided for @fileNotExist.
  ///
  /// In en, this message translates to:
  /// **'The file does not exist.'**
  String get fileNotExist;

  /// No description provided for @dataCannotLoadedFromFolder.
  ///
  /// In en, this message translates to:
  /// **'Data cannot be loaded from the folder.'**
  String get dataCannotLoadedFromFolder;

  /// No description provided for @allAvailableResources.
  ///
  /// In en, this message translates to:
  /// **'All available resources have been added.'**
  String get allAvailableResources;

  /// No description provided for @addResources.
  ///
  /// In en, this message translates to:
  /// **'Add resources'**
  String get addResources;

  /// No description provided for @resourceAllocation.
  ///
  /// In en, this message translates to:
  /// **'Custom resources'**
  String get resourceAllocation;

  /// No description provided for @enableSecondsAsTheUnit.
  ///
  /// In en, this message translates to:
  /// **'Enable seconds as the unit.'**
  String get enableSecondsAsTheUnit;

  /// No description provided for @disableTheUseOfSecondsAsTheUnit.
  ///
  /// In en, this message translates to:
  /// **'Disable the use of seconds as the unit.'**
  String get disableTheUseOfSecondsAsTheUnit;

  /// No description provided for @addCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add code'**
  String get addCodeTitle;

  /// No description provided for @searchTitleOrDescription.
  ///
  /// In en, this message translates to:
  /// **'Search for the title or description.'**
  String get searchTitleOrDescription;

  /// No description provided for @allAvailableCodesHaveBeenAdded.
  ///
  /// In en, this message translates to:
  /// **'All available codes have been added.'**
  String get allAvailableCodesHaveBeenAdded;

  /// No description provided for @addCodeTip.
  ///
  /// In en, this message translates to:
  /// **'Add %d lines of code'**
  String get addCodeTip;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get cancel;

  /// No description provided for @hideExistingItems.
  ///
  /// In en, this message translates to:
  /// **'Hide existing items'**
  String get hideExistingItems;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @unfold.
  ///
  /// In en, this message translates to:
  /// **'Unfold'**
  String get unfold;

  /// No description provided for @displayEscapeCharacters.
  ///
  /// In en, this message translates to:
  /// **'Display escape characters'**
  String get displayEscapeCharacters;

  /// No description provided for @escapeCharacterGuide.
  ///
  /// In en, this message translates to:
  /// **'Escape character guide: \\n represents a newline, \\r represents a carriage return, and \\t represents a tab character.'**
  String get escapeCharacterGuide;

  /// No description provided for @editingSequence.
  ///
  /// In en, this message translates to:
  /// **'Editing sequence'**
  String get editingSequence;

  /// No description provided for @translationMode.
  ///
  /// In en, this message translates to:
  /// **'Translation Mode'**
  String get translationMode;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @doYouWantDeleteThisComment.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the comment \"%s\"?'**
  String get doYouWantDeleteThisComment;

  /// No description provided for @doYouWantDeleteThisCode.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the code \"%s\"?'**
  String get doYouWantDeleteThisCode;

  /// No description provided for @doYouWantDelete.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete \"%s\"?'**
  String get doYouWantDelete;

  /// No description provided for @convertToCode.
  ///
  /// In en, this message translates to:
  /// **'Convert to code'**
  String get convertToCode;

  /// No description provided for @convertToAnnotations.
  ///
  /// In en, this message translates to:
  /// **'Convert to annotations'**
  String get convertToAnnotations;

  /// No description provided for @fileHasBeenSaved.
  ///
  /// In en, this message translates to:
  /// **'\"%s\" has been saved.'**
  String get fileHasBeenSaved;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code(%s)'**
  String get sourceCode;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @visual.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get visual;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @languageAndAppearance.
  ///
  /// In en, this message translates to:
  /// **'Language and Appearance'**
  String get languageAndAppearance;

  /// No description provided for @dynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get dynamicColor;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get confirm;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @darkColor.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkColor;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @visitTheSteamWorkshopHomepage.
  ///
  /// In en, this message translates to:
  /// **'Visit the Steam Workshop homepage'**
  String get visitTheSteamWorkshopHomepage;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @addFunction.
  ///
  /// In en, this message translates to:
  /// **'Add function'**
  String get addFunction;

  /// No description provided for @searchFunction.
  ///
  /// In en, this message translates to:
  /// **'Search function'**
  String get searchFunction;

  /// No description provided for @addFunctionTip.
  ///
  /// In en, this message translates to:
  /// **'Add %d functions'**
  String get addFunctionTip;

  /// No description provided for @noAvailableFunction.
  ///
  /// In en, this message translates to:
  /// **'No available function'**
  String get noAvailableFunction;

  /// No description provided for @addMod.
  ///
  /// In en, this message translates to:
  /// **'Add Mod'**
  String get addMod;

  /// No description provided for @createMod.
  ///
  /// In en, this message translates to:
  /// **'Create Mod'**
  String get createMod;

  /// No description provided for @importMod.
  ///
  /// In en, this message translates to:
  /// **'Import Mod'**
  String get importMod;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsTip.
  ///
  /// In en, this message translates to:
  /// **'Use, split tags.'**
  String get tagsTip;

  /// No description provided for @minVersion.
  ///
  /// In en, this message translates to:
  /// **'Min Version'**
  String get minVersion;

  /// No description provided for @modRepeatedlyPrompts.
  ///
  /// In en, this message translates to:
  /// **'Mod %s already exists.'**
  String get modRepeatedlyPrompts;

  /// No description provided for @fileRepeatedlyPrompts.
  ///
  /// In en, this message translates to:
  /// **'File %s already exists.'**
  String get fileRepeatedlyPrompts;

  /// No description provided for @titleContainsIllegalCharacter.
  ///
  /// In en, this message translates to:
  /// **'Contains illegal characters: \\ / : *? \"<'**
  String get titleContainsIllegalCharacter;

  /// No description provided for @titleCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get titleCannotBeEmpty;

  /// No description provided for @modCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Mod created successfully'**
  String get modCreatedSuccessfully;

  /// No description provided for @modCreatedSuccessfullyTitle.
  ///
  /// In en, this message translates to:
  /// **'Mod created successfully'**
  String get modCreatedSuccessfullyTitle;

  /// No description provided for @whetherOpenWorkspaceImmediately.
  ///
  /// In en, this message translates to:
  /// **'Whether open workspace immediately?'**
  String get whetherOpenWorkspaceImmediately;

  /// No description provided for @rememberMyChoice.
  ///
  /// In en, this message translates to:
  /// **'Remember my choice'**
  String get rememberMyChoice;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openWorkSpace.
  ///
  /// In en, this message translates to:
  /// **'Open workspace'**
  String get openWorkSpace;

  /// No description provided for @modCreatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Mod created Failed'**
  String get modCreatedFailed;

  /// No description provided for @modCreatedFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Mod created failed error info: %s'**
  String get modCreatedFailedMessage;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'statistics'**
  String get statistics;

  /// No description provided for @statisticsFiles.
  ///
  /// In en, this message translates to:
  /// **'statistics %d files...'**
  String get statisticsFiles;

  /// No description provided for @moveToRecyclingBin.
  ///
  /// In en, this message translates to:
  /// **'Move to recycling bin'**
  String get moveToRecyclingBin;

  /// No description provided for @moveToRecyclingBinMessage.
  ///
  /// In en, this message translates to:
  /// **'Moving file (%d/%d): %s .'**
  String get moveToRecyclingBinMessage;

  /// No description provided for @cleanTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get cleanTitle;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning...'**
  String get cleaning;

  /// No description provided for @moveToRecycleBinFail.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed.'**
  String get moveToRecycleBinFail;

  /// No description provided for @moveToRecycleBinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deletion successful.'**
  String get moveToRecycleBinSuccess;

  /// No description provided for @moveToRecycleBinCancel.
  ///
  /// In en, this message translates to:
  /// **'Has been cancelled and deleted.'**
  String get moveToRecycleBinCancel;

  /// No description provided for @noModWasFound.
  ///
  /// In en, this message translates to:
  /// **'No mod was found'**
  String get noModWasFound;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchByTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by title'**
  String get searchByTitle;

  /// No description provided for @searchByTitleAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Search by title and description'**
  String get searchByTitleAndDescription;

  /// No description provided for @noMatchingModWasFound.
  ///
  /// In en, this message translates to:
  /// **'No matching mod was found'**
  String get noMatchingModWasFound;

  /// No description provided for @pleaseTryUsingOtherKeywords.
  ///
  /// In en, this message translates to:
  /// **'Please try using other keywords'**
  String get pleaseTryUsingOtherKeywords;

  /// No description provided for @navigateToTheDirectoryWhereTheFileIsLocated.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the directory where the file is located'**
  String get navigateToTheDirectoryWhereTheFileIsLocated;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @noResultsUnderThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No results under this category'**
  String get noResultsUnderThisCategory;

  /// No description provided for @noDataAvailableForSearch.
  ///
  /// In en, this message translates to:
  /// **'No data available for search'**
  String get noDataAvailableForSearch;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global search'**
  String get globalSearch;

  /// No description provided for @indexIsBeingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updating index...'**
  String get indexIsBeingUpdated;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @lastUpdateTime.
  ///
  /// In en, this message translates to:
  /// **'Last update time: %s, time consumption: %s.'**
  String get lastUpdateTime;

  /// No description provided for @toggleLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Toggle Line Number'**
  String get toggleLineNumber;

  /// No description provided for @showSourceDiff.
  ///
  /// In en, this message translates to:
  /// **'Show Source Diff'**
  String get showSourceDiff;

  /// No description provided for @jumpTo.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get jumpTo;

  /// No description provided for @lineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line Number'**
  String get lineNumber;

  /// No description provided for @maxLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Max %d Line Number.'**
  String get maxLineNumber;

  /// No description provided for @fileNameOrFolderName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fileNameOrFolderName;

  /// No description provided for @createdAsFolder.
  ///
  /// In en, this message translates to:
  /// **'Created as a folder'**
  String get createdAsFolder;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSection;

  /// No description provided for @noSectionWereDetected.
  ///
  /// In en, this message translates to:
  /// **'No Section was detected'**
  String get noSectionWereDetected;

  /// No description provided for @startQuickly.
  ///
  /// In en, this message translates to:
  /// **'Start Quickly'**
  String get startQuickly;

  /// No description provided for @createNewFile.
  ///
  /// In en, this message translates to:
  /// **'Create a file'**
  String get createNewFile;

  /// No description provided for @openAnExistingFile.
  ///
  /// In en, this message translates to:
  /// **'Open an file'**
  String get openAnExistingFile;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// No description provided for @repeatedSectionNames.
  ///
  /// In en, this message translates to:
  /// **'Repeated section name'**
  String get repeatedSectionNames;

  /// No description provided for @storageAccessFramework.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Framework'**
  String get storageAccessFramework;

  /// No description provided for @storageAccessFrameworkDefault.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Framework(Default)'**
  String get storageAccessFrameworkDefault;

  /// No description provided for @storageAccessFrameworkOpenDescription.
  ///
  /// In en, this message translates to:
  /// **'Accesses only the folder you choose. More secure, but slower when handling large numbers of files.'**
  String get storageAccessFrameworkOpenDescription;

  /// No description provided for @storageAccessFrameworkCloseDescription.
  ///
  /// In en, this message translates to:
  /// **'Directly accesses storage for faster speed, but requires the \"Manage all files\" permission.'**
  String get storageAccessFrameworkCloseDescription;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'permission'**
  String get permission;

  /// No description provided for @revokeGrantedAccessPermissionSAFDirectory.
  ///
  /// In en, this message translates to:
  /// **'Revoke Directory Access Permission'**
  String get revokeGrantedAccessPermissionSAFDirectory;

  /// No description provided for @revokeGrantedAccessPermissionSAFDirectoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Revoke the directory access permissions granted to the app, no further access allowed.'**
  String get revokeGrantedAccessPermissionSAFDirectoryDescription;

  /// No description provided for @noSAFDirectoryPermissions.
  ///
  /// In en, this message translates to:
  /// **'No directory access permissions available to revoke.'**
  String get noSAFDirectoryPermissions;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke %d Permissions'**
  String get revoke;

  /// No description provided for @revocationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Permission revoked. Restart app to clear cache.'**
  String get revocationSuccessful;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'selectAll'**
  String get selectAll;

  /// No description provided for @suggestionsForCloseTheSAF.
  ///
  /// In en, this message translates to:
  /// **'Granting the \"Manage All Files\" permission can significantly improve file read and write speeds.'**
  String get suggestionsForCloseTheSAF;

  /// No description provided for @closeSAF.
  ///
  /// In en, this message translates to:
  /// **'Switch Mode'**
  String get closeSAF;

  /// No description provided for @manageAllFile.
  ///
  /// In en, this message translates to:
  /// **'All files access'**
  String get manageAllFile;

  /// No description provided for @selectTheStorageMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select the storage access mode'**
  String get selectTheStorageMethod;

  /// No description provided for @currentMode1.
  ///
  /// In en, this message translates to:
  /// **'Current mode: Storage access framework'**
  String get currentMode1;

  /// No description provided for @currentMode2.
  ///
  /// In en, this message translates to:
  /// **'Current mode: Access all files'**
  String get currentMode2;

  /// No description provided for @currentMode3.
  ///
  /// In en, this message translates to:
  /// **'Current mode: Access all files (effective after authorization)'**
  String get currentMode3;

  /// No description provided for @authorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get authorization;

  /// No description provided for @allFileAccessPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'All file access permission Settings'**
  String get allFileAccessPermissionSettings;

  /// No description provided for @selectTheFolder.
  ///
  /// In en, this message translates to:
  /// **'Select the folder'**
  String get selectTheFolder;

  /// No description provided for @selectObjet.
  ///
  /// In en, this message translates to:
  /// **'Select %s'**
  String get selectObjet;

  /// No description provided for @pathIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The path section you configured has expired. The folder may have been deleted or the folder access permission may have been revoked.'**
  String get pathIsUnavailable;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @directoryDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'The directory does not exist.'**
  String get directoryDoesNotExist;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @automaticIndexConstruction.
  ///
  /// In en, this message translates to:
  /// **'Automatic Index Construction'**
  String get automaticIndexConstruction;

  /// No description provided for @automaticIndexConstructionTip.
  ///
  /// In en, this message translates to:
  /// **'When the file is saved or you return from other applications, retrieve the project changes for automatic prompts and global search.'**
  String get automaticIndexConstructionTip;

  /// No description provided for @addSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSectionTitle;

  /// No description provided for @addSectionTip.
  ///
  /// In en, this message translates to:
  /// **'Add %d section'**
  String get addSectionTip;

  /// No description provided for @fileNotSupportedOpening.
  ///
  /// In en, this message translates to:
  /// **'This file is not supported for opening for the time being.'**
  String get fileNotSupportedOpening;

  /// No description provided for @displayOperationOptions.
  ///
  /// In en, this message translates to:
  /// **'Display operation options'**
  String get displayOperationOptions;

  /// No description provided for @lineHasBeenMarked.
  ///
  /// In en, this message translates to:
  /// **'Line %d has been marked'**
  String get lineHasBeenMarked;

  /// No description provided for @eliminateTheMark.
  ///
  /// In en, this message translates to:
  /// **'Eliminate the mark'**
  String get eliminateTheMark;

  /// No description provided for @attachedFiles.
  ///
  /// In en, this message translates to:
  /// **'Attached files'**
  String get attachedFiles;

  /// No description provided for @selectTheFile.
  ///
  /// In en, this message translates to:
  /// **'Select the files'**
  String get selectTheFile;

  /// No description provided for @noFilesFolders.
  ///
  /// In en, this message translates to:
  /// **'There are no files or folders.'**
  String get noFilesFolders;

  /// No description provided for @noMatchingFileFolderWasFound.
  ///
  /// In en, this message translates to:
  /// **'No matching file or folder was found.'**
  String get noMatchingFileFolderWasFound;

  /// No description provided for @selectNumberFiles.
  ///
  /// In en, this message translates to:
  /// **'Select %d files'**
  String get selectNumberFiles;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'remove'**
  String get remove;

  /// No description provided for @invalidCitation.
  ///
  /// In en, this message translates to:
  /// **'Invalid citation'**
  String get invalidCitation;

  /// No description provided for @pointedNotExist.
  ///
  /// In en, this message translates to:
  /// **'The file %s pointed to does not exist.'**
  String get pointedNotExist;

  /// No description provided for @autoSave.
  ///
  /// In en, this message translates to:
  /// **'autoSave'**
  String get autoSave;

  /// No description provided for @autoSaveTip.
  ///
  /// In en, this message translates to:
  /// **'The currently edited file is automatically saved when you switch applications.'**
  String get autoSaveTip;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'selectColor'**
  String get selectColor;

  /// No description provided for @unitsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Units template'**
  String get unitsTemplate;

  /// No description provided for @createdFromUnitTemplate.
  ///
  /// In en, this message translates to:
  /// **'Created from the unit template'**
  String get createdFromUnitTemplate;

  /// No description provided for @addTags.
  ///
  /// In en, this message translates to:
  /// **'Add Tags'**
  String get addTags;

  /// No description provided for @addTagsTip.
  ///
  /// In en, this message translates to:
  /// **'Add %d tags'**
  String get addTagsTip;

  /// No description provided for @showOrHideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the sidebar'**
  String get showOrHideSidebar;

  /// No description provided for @targetGameVersion.
  ///
  /// In en, this message translates to:
  /// **'Target game version'**
  String get targetGameVersion;

  /// No description provided for @targetGameVersionMessage.
  ///
  /// In en, this message translates to:
  /// **'After selecting the target game version, the application only displays the data available for the target game version. For example, if 1.14 is selected, only the data of versions 1.13 and 1.14 will be displayed. 1.15 is not included.'**
  String get targetGameVersionMessage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get clear;

  /// No description provided for @wantToClearThisFileReference.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear this file reference?'**
  String get wantToClearThisFileReference;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get auto;

  /// No description provided for @wantToSetThisFileReferenceToAuto.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to set this file reference to automatic?'**
  String get wantToSetThisFileReferenceToAuto;

  /// No description provided for @autoAnimated.
  ///
  /// In en, this message translates to:
  /// **'Auto Animated'**
  String get autoAnimated;

  /// No description provided for @wantToSetThisFileReferenceToAutoAnimated.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to set this file reference to automatic animated?'**
  String get wantToSetThisFileReferenceToAutoAnimated;

  /// No description provided for @repeatedDefinition.
  ///
  /// In en, this message translates to:
  /// **'Repeated definition'**
  String get repeatedDefinition;

  /// No description provided for @returnText.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnText;

  /// No description provided for @core.
  ///
  /// In en, this message translates to:
  /// **'core'**
  String get core;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'shared'**
  String get shared;

  /// No description provided for @dragTheFileHere.
  ///
  /// In en, this message translates to:
  /// **'Drag the file here'**
  String get dragTheFileHere;

  /// No description provided for @modNotBeenResolvedFromSelectedPath.
  ///
  /// In en, this message translates to:
  /// **'The module has not been resolved from the directory you selected.'**
  String get modNotBeenResolvedFromSelectedPath;

  /// No description provided for @analysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'Analysis in progress. Please wait for a moment...'**
  String get analysisInProgress;

  /// No description provided for @modAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'The module already exists.'**
  String get modAlreadyExists;

  /// No description provided for @readInfoArchiveFile.
  ///
  /// In en, this message translates to:
  /// **'Load archive file information'**
  String get readInfoArchiveFile;

  /// No description provided for @readInfoArchiveFileSub.
  ///
  /// In en, this message translates to:
  /// **'Load icons, titles, and other information from zip or rwmod format files. Displayed in the mod list.'**
  String get readInfoArchiveFileSub;

  /// No description provided for @readInfoArchiveFile0Mb.
  ///
  /// In en, this message translates to:
  /// **'Do not load'**
  String get readInfoArchiveFile0Mb;

  /// No description provided for @readInfoArchiveFile1Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 1MB'**
  String get readInfoArchiveFile1Mb;

  /// No description provided for @readInfoArchiveFile3Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 3MB'**
  String get readInfoArchiveFile3Mb;

  /// No description provided for @readInfoArchiveFile5Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 5MB'**
  String get readInfoArchiveFile5Mb;

  /// No description provided for @readInfoArchiveFile10Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 10MB'**
  String get readInfoArchiveFile10Mb;

  /// No description provided for @readInfoArchiveFile30Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 30MB'**
  String get readInfoArchiveFile30Mb;

  /// No description provided for @readInfoArchiveFile50Mb.
  ///
  /// In en, this message translates to:
  /// **'Less than 50MB'**
  String get readInfoArchiveFile50Mb;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @discoverNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version %s has been discovered'**
  String get discoverNewVersion;

  /// No description provided for @linkCannotBeOpened.
  ///
  /// In en, this message translates to:
  /// **'The link cannot be opened.'**
  String get linkCannotBeOpened;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @failedToObtainDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to obtain the download link.'**
  String get failedToObtainDownloadLink;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for update'**
  String get checkForUpdate;

  /// No description provided for @versionName.
  ///
  /// In en, this message translates to:
  /// **'Version Name'**
  String get versionName;

  /// No description provided for @versionNumber.
  ///
  /// In en, this message translates to:
  /// **'Version Number'**
  String get versionNumber;

  /// No description provided for @includesPreReleaseVersion.
  ///
  /// In en, this message translates to:
  /// **'includes Pre-Release Version'**
  String get includesPreReleaseVersion;

  /// No description provided for @versionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Version update'**
  String get versionUpdate;

  /// No description provided for @isLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'It\'s already the latest version.'**
  String get isLatestVersion;

  /// No description provided for @agreementsAndPolicies.
  ///
  /// In en, this message translates to:
  /// **'Agreements and Policies'**
  String get agreementsAndPolicies;

  /// No description provided for @descriptionOfPermissionGranting.
  ///
  /// In en, this message translates to:
  /// **'We need you to grant storage permission in order to access the mod files on your device.'**
  String get descriptionOfPermissionGranting;

  /// No description provided for @decompress.
  ///
  /// In en, this message translates to:
  /// **'Decompress'**
  String get decompress;

  /// No description provided for @deleteOriginalFile.
  ///
  /// In en, this message translates to:
  /// **'Delete the original file after decompression is completed.'**
  String get deleteOriginalFile;

  /// No description provided for @doYouLikeDecompressTheSourceFile.
  ///
  /// In en, this message translates to:
  /// **'This file can only be edited after being decompressed. Do you want to start decompressing \"%s\"?'**
  String get doYouLikeDecompressTheSourceFile;

  /// No description provided for @folderAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'The decompressed folder already exists.'**
  String get folderAlreadyExists;

  /// No description provided for @extractTip.
  ///
  /// In en, this message translates to:
  /// **'Extract (%d/%d): %s'**
  String get extractTip;

  /// No description provided for @readTheFile.
  ///
  /// In en, this message translates to:
  /// **'Read the file...'**
  String get readTheFile;

  /// No description provided for @openWorkSpaceAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get openWorkSpaceAsk;

  /// No description provided for @openWorkSpaceAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get openWorkSpaceAlways;

  /// No description provided for @openWorkSpaceNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get openWorkSpaceNever;

  /// No description provided for @openWorkspaceAfterCreatingTheFile.
  ///
  /// In en, this message translates to:
  /// **'After creating the mod, open the workspace'**
  String get openWorkspaceAfterCreatingTheFile;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'recycleBin'**
  String get recycleBin;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'restore'**
  String get restore;

  /// No description provided for @restoreToOriginalPosition.
  ///
  /// In en, this message translates to:
  /// **'Do you want to restore \"%s\" to its original position \"%s\"?'**
  String get restoreToOriginalPosition;

  /// No description provided for @fileAlreadyExistsAtTheOriginalLocation.
  ///
  /// In en, this message translates to:
  /// **'The file already exists at the original location.'**
  String get fileAlreadyExistsAtTheOriginalLocation;

  /// No description provided for @decompressionHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'Decompression has been cancelled.'**
  String get decompressionHasBeenCancelled;

  /// No description provided for @restorationHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'The restoration has been cancelled.'**
  String get restorationHasBeenCancelled;

  /// No description provided for @restoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Restored successfully.'**
  String get restoredSuccessfully;

  /// No description provided for @foreverDelete.
  ///
  /// In en, this message translates to:
  /// **'foreverDelete'**
  String get foreverDelete;

  /// No description provided for @wantToForeverDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"%s\"? Once deleted, it cannot be restored.'**
  String get wantToForeverDelete;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import file'**
  String get importFile;

  /// No description provided for @copyFileing.
  ///
  /// In en, this message translates to:
  /// **'Copy the file...'**
  String get copyFileing;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @createModInfo.
  ///
  /// In en, this message translates to:
  /// **'Create mod-info.txt'**
  String get createModInfo;

  /// No description provided for @createAllTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create all-units.template'**
  String get createAllTemplate;

  /// No description provided for @createFileOrFolder.
  ///
  /// In en, this message translates to:
  /// **'Create a file or folder'**
  String get createFileOrFolder;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// No description provided for @clearRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'Empty the Recycle Bin'**
  String get clearRecycleBin;

  /// No description provided for @wantToClearRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to empty the Recycle Bin?'**
  String get wantToClearRecycleBin;

  /// No description provided for @clearRecycleBinSuccess.
  ///
  /// In en, this message translates to:
  /// **'The Recycle Bin has been emptied successfully'**
  String get clearRecycleBinSuccess;

  /// No description provided for @clearRecycleBinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to empty the Recycle Bin'**
  String get clearRecycleBinFailed;

  /// No description provided for @agreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get agreement;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'view'**
  String get view;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get all;

  /// No description provided for @decompressionFailed.
  ///
  /// In en, this message translates to:
  /// **'decompression Failed'**
  String get decompressionFailed;

  /// No description provided for @pleaseSwitchToAnotherDecompression.
  ///
  /// In en, this message translates to:
  /// **'Please switch to another decompression tool. File decompression error: %s'**
  String get pleaseSwitchToAnotherDecompression;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'global'**
  String get global;

  /// No description provided for @customResourceHaveNotBeenUsedYet.
  ///
  /// In en, this message translates to:
  /// **'Custom resources have not been used yet'**
  String get customResourceHaveNotBeenUsedYet;

  /// No description provided for @viewAllResources.
  ///
  /// In en, this message translates to:
  /// **'View all resources'**
  String get viewAllResources;

  /// No description provided for @thereAreNoAvailableCustomResources.
  ///
  /// In en, this message translates to:
  /// **'If there are no available custom resources.'**
  String get thereAreNoAvailableCustomResources;

  /// No description provided for @customResourcesCannotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Custom resources cannot be found'**
  String get customResourcesCannotBeFound;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'Github'**
  String get github;

  /// No description provided for @githubSub.
  ///
  /// In en, this message translates to:
  /// **'View the source code of the software on Github'**
  String get githubSub;

  /// No description provided for @bilibili.
  ///
  /// In en, this message translates to:
  /// **'BiliBili'**
  String get bilibili;

  /// No description provided for @bilibiliSub.
  ///
  /// In en, this message translates to:
  /// **'Follow us on bilibili!'**
  String get bilibiliSub;

  /// No description provided for @removeAllCodeWithInSection.
  ///
  /// In en, this message translates to:
  /// **'This will remove all the code within the section. Do you still want to delete it?'**
  String get removeAllCodeWithInSection;

  /// No description provided for @citationUnit.
  ///
  /// In en, this message translates to:
  /// **'Citation unit'**
  String get citationUnit;

  /// No description provided for @unitSelector.
  ///
  /// In en, this message translates to:
  /// **'Unit selector'**
  String get unitSelector;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @readMagicNumberOfFiles.
  ///
  /// In en, this message translates to:
  /// **'Read the magic number of files'**
  String get readMagicNumberOfFiles;

  /// No description provided for @readMagicNumberOfFilesTip.
  ///
  /// In en, this message translates to:
  /// **'Infer the file type by reading the first 16 bytes of the file\'s data, rather than determining it based on the file format. For example, if a.png is named a, the software infers the file type based on the first 16 bytes of data, even if the file suffix is not png.'**
  String get readMagicNumberOfFilesTip;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
