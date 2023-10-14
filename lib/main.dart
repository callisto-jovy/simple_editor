import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/error_page.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/utils/file_util.dart' as file_util;
import 'package:video_editor/widgets/file_drop.dart';

const jarError = 'No JAR files were found.\n'
    'Run `dart run jnigen:download_maven_jars --config jnigen.yaml` '
    'in plugin directory.\n'
    'Alternatively, regenerate JNI bindings in plugin directory, which will '
    'automatically download the JAR files.';
// It's required to manually provide the JAR files as classpath when
// spawning the JVM.
const jarDir = 'mvn_jar';

Future<void> main() async {
  final List<String> jars;
  try {
    jars = Directory(jarDir)
        .listSync()
        .map((e) => e.path)
        .where((path) => path.endsWith('.jar'))
        .toList();
  } on OSError catch (_) {
    stderr.writeln(jarError);
    return;
  }
  if (jars.isEmpty) {
    stderr.writeln(jarError);
    return;
  }

  Jni.spawn(
    dylibDir: join('build', 'jni_libs'),
    classPath: ['easy_edits/core/target/classes', ...jars],
  );

  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  await localNotifier.setup(
    appName: 'local_notifier_example',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );

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

  Future<void> _edit() async {
    await config.ensureOutExists();
    //TODO: Make sure that the state is fulfilled.
    final String json = config.toJson();
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
    final String json = config.toJson();
    // Run the export process in a new isolate
    await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(json))).then((value) {
      LocalNotification(
        title: 'Easy Edits',
        body: 'Done exporting the segments.',
      ).show();
    });
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
                child: const Text('Settings'),
              ),
              TextButton(
                onPressed: () => _saveFile(),
                child: const Text('Export'),
              ),
              TextButton(
                onPressed: () => _loadFile(),
                child: const Text('Import'),
              ),
              TextButton(
                onPressed: () => _edit(),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _exportSegments(),
                child: const Text('Export Segments'),
              )
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
