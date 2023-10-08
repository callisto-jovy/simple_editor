import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/error_page.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config_util.dart';
import 'package:video_editor/utils/file_util.dart' as file_util;
import 'package:video_editor/widgets/file_drop.dart';

void main() {
  Jni.spawn(
    dylibDir: join('build', 'jni_libs'),
    classPath: ['TarsosDSP/core/build/classes/java/main'],
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
      audioPath = path;
      pageBuilder = (context) => const AudioAnalysis();
    } else if (file_util.isFileVideo(path)) {
      videoPath = path;

      pageBuilder = (context) => const VideoPlayer();
    } else {
      pageBuilder = (context) => const ErrorPage(
          errorMessage: 'Wrong file-format. Please make sure that the supplied file compatible.',
          subtext: 'Compatible file formats: Video: HVEC, Audio: WAV.');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: pageBuilder),
    );
  }

  void _saveFile() async {
    final String? result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export data',
      fileName: '${path.basename(videoPath)}.json',
    );
    final File? file = result == null ? null : File(result);
    exportFile(file: file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Export ',
            onPressed: () => _saveFile(),
            icon: const Icon(Icons.save),
          ),
        ],
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Divider(height: 2),
          FileDrop(
            fileType: 'Video or Audio',
            fileDropped: (file) => _navigateRoute(context, file.path),
          ),
        ],
      ),
    );
  }
}
