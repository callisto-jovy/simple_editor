import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:video_editor/pages/create/create_project_page.dart';
import 'package:video_editor/pages/main_project_page.dart';
import 'package:video_editor/utils/config/config.dart' as config;
import 'package:video_editor/utils/backend/jni_util.dart';
import 'package:video_editor/widgets/styles.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  // First thing: Start the backend.
  spawnJNI();
  // Necessary for package:window_manager
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();
  // Window manager for native callbacks. In our case: window close.
  await windowManager.ensureInitialized();
  // native notifications.
  await localNotifier.setup(appName: 'Easy Edits', shortcutPolicy: ShortcutPolicy.requireCreate);

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
