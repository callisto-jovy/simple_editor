import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart';
import 'package:video_editor/pages/create_project_page.dart';
import 'package:video_editor/pages/main_project_page.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/widgets/styles.dart';

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
  void _navigatePage(final BuildContext context, final WidgetBuilder page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: page,
      ),
    );
  }

  void _navigateWOBack(final BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
        (Route<dynamic> route) => false);
  }

  void _importProject(Function() importDone) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import save file',
      allowMultiple: false,
    );

    if (result != null) {
      config.importFile(path: result.files[0].path);
      importDone.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              TextButton(
                onPressed: () => _navigatePage(context, (context) => const CreateProjectPage()),
                style: textButtonStyle(context),
                child: const Text('New Project'),
              ),
              TextButton(
                onPressed: () => _importProject(() => _navigateWOBack(context)),
                style: textButtonStyle(context),
                child: const Text('Import'),
              )
            ]
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: e,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
