import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:rust_assistant/mod/mod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'edit_units_page.dart';

class ModActionPage extends StatefulWidget {
  final Mod mod;

  const ModActionPage({super.key, required this.mod});

  @override
  State<ModActionPage> createState() => _ModActionPageState();
}

class _ModActionPageState extends State<ModActionPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              textAlign: TextAlign.left,
              widget.mod.modName ?? AppLocalizations.of(context)!.none,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              textAlign: TextAlign.left,
              widget.mod.modDescription ?? AppLocalizations.of(context)!.none,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.editUnit),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return EditUnitsPage(mod: widget.mod);
                  },
                ),
              );
            },
          ),
          if (Platform.isLinux || Platform.isWindows)
            ListTile(
              title: Text(AppLocalizations.of(context)!.openItInTheFileManager),
              onTap: () async {
                var modPath = widget.mod.path;
                if (!widget.mod.isDirectory) {
                  //如果不是文件夹，那么获取文件所在目录
                  modPath = path.dirname(modPath);
                }
                final uri = Uri.parse("file:$modPath");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.fail),
                      ),
                    );
                  }
                }
              },
            ),
          if (widget.mod.steamId != null)
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.visitTheSteamWorkshopHomepage,
              ),
              onTap: () async {
                var steamId = widget.mod.steamId;
                final uri = Uri.parse(
                  "https://steamcommunity.com/sharedfiles/filedetails/?id=$steamId",
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.fail),
                      ),
                    );
                  }
                }
              },
            ),
          ListTile(title: Text(AppLocalizations.of(context)!.delete)),
        ],
      ),
    );
  }
}
