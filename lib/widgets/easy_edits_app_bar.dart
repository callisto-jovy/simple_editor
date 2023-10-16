import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:video_editor/pages/main_project_page.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';


void _loadFile(Function() callback) async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Import save file',
    allowMultiple: false,
  );

  if (result != null) {
    config.importFile(path: result.files[0].path);
    callback.call();
  }
}

Future<void> _edit() async {
  await config.ensureOutExists();
  //TODO: Make sure that the state is fulfilled.
  final String json = config.toEditorConfig();
  // Run the export process in a new isolate
  await Isolate.run(() => FlutterWrapper.edit(JString.fromString(json))).then((value) {
    LocalNotification(
      title: 'Easy Edits',
      body: 'Done editing.',
    ).show();
  });
}

Future<void> _exportSegments() async {
  await config.ensureOutExists();
  //TODO: Make sure that the state is fulfilled.
  final String json = config.toEditorConfig();
  // Run the export process in a new isolate
  await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(json))).then((value) {
    LocalNotification(
      title: 'Easy Edits',
      body: 'Done exporting the segments.',
    ).show();
  });
}

List<Widget> appBarTrailing(final BuildContext context) {
  return [
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      },
      child: const Text('Settings'),
    ),
    TextButton(
      onPressed: () => _loadFile(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loaded config for ${config.videoProject.projectName}'),
        ));

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
            (Route<dynamic> route) => false);
      }),
      child: const Text('Import'),
    ),
    TextButton(
      onPressed: () => _edit(),
      child: const Text('Edit'),
    ),
    TextButton(
      onPressed: () => _exportSegments(),
      child: const Text('Export Segments'),
    ),
  ];
}

AppBar mainAppBar(final BuildContext context) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    centerTitle: true,
    title: const Text('Easy Edits'),
    actions: appBarTrailing(context),
  );
}
