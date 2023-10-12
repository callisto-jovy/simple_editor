import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/error_page.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config_util.dart' as config;
import 'package:video_editor/utils/fast_edits_backend.dart';
import 'package:video_editor/utils/file_util.dart' as file_util;
import 'package:video_editor/widgets/file_drop.dart';
import 'package:icons_plus/icons_plus.dart';



void main() {
  Jni.spawn(
    dylibDir: join('build', 'jni_libs'),
    classPath: ['fast_edits_backend/target/classes'],
  );


  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Edits',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0x007EA2BF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Easy Edits'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _navigateRoute(final BuildContext context, final String path) {
    final WidgetBuilder pageBuilder;

    if (file_util.isFileAudio(path)) {
      config.audioPath = path;
      pageBuilder = (context) => const AudioAnalysis();
    } else if (file_util.isFileVideo(path)) {
      config.videoPath = path;

      pageBuilder = (context) => const VideoPlayer();
    } else {
      pageBuilder = (context) => const ErrorPage(
          errorMessage: 'Wrong file-format. Please make sure that the supplied file compatible.',
          subtext: 'Compatible file formats: Video: HEVC, Audio: WAV.');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: pageBuilder),
    );
  }

  void _saveFile() async {
    final String? result = await FilePicker.platform.saveFile(
      allowedExtensions: ['json'],
      dialogTitle: 'Export data',
      fileName: '${path.basename(config.videoPath)}.json',
    );
    final File? file = result == null ? null : File(result);
    config.exportFile(file: file);
  }

  void _loadFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import save file',
      allowMultiple: false,
    );

    if (result != null) {
      config.importFile(path: result.files[0].path);
    }
  }

  void _edit() async {
    //TODO: Make sure that the state is fulfilled.
    final String json = config.toJson();

    EditorWrapper.edit(JString.fromString(json), false);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: const Text('Editing options'),
              ),
              TextButton(
                onPressed: () => _saveFile(),
                child: const Text('Export'),
              ),
              TextButton(
                onPressed: () => _loadFile(),
                child: const Text('Import'),
              ),
              TextButton(onPressed: () => _edit(), child: const Text('Edit'))
            ],
          ),
        ],
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: size.width - 50,
          height: size.height - 100,
          child: MediaFileDrop(
            fileType: 'Video or Audio',
            fileDropped: (file) => _navigateRoute(context, file.path),
          ),
        ),
      ),
    );
  }
}
