import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:video_editor/pages/audio_analysis_page.dart';
import 'package:video_editor/pages/clip_adjust_page.dart';
import 'package:video_editor/pages/clip_selection_page.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/utils/backend/backend_util.dart';
import 'package:video_editor/utils/config/config.dart' as config;
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/snackbars.dart';
import 'package:video_editor/widgets/styles.dart';
import 'package:video_editor/widgets/time_stamp_widget.dart';
import 'package:window_manager/window_manager.dart';

class MainProjectPage extends StatefulWidget {
  const MainProjectPage({super.key});

  @override
  State<MainProjectPage> createState() => _MainProjectPageState();
}

class _MainProjectPageState extends State<MainProjectPage> with WindowListener {
  /// [TextEditingController] which controls the video path
  final TextEditingController _videoPathController =
      TextEditingController(text: config.videoProject.config.videoPath);

  /// [TextEditingController] which controls the audio path
  final TextEditingController _audioPathController =
      TextEditingController(text: config.videoProject.config.audioPath);

  /// [TextEditingController] which controls the project name
  final TextEditingController _projectNameController =
      TextEditingController(text: config.videoProject.projectName);

  /// [TextEditingController] which controls the project path.
  final TextEditingController _projectPathController =
      TextEditingController(text: config.videoProject.projectPath);

  @override
  void dispose() {
    super.dispose();
    _videoPathController.dispose();
    _audioPathController.dispose();
    _projectNameController.dispose();
    _projectPathController.dispose();
    // Remove the window manager listener
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    super.initState();
    // Add a new listener for the window closing.
    windowManager.addListener(this);

    windowManager.setPreventClose(true);

    setState(() {});
  }

  @override
  void onWindowClose() {
    windowManager.isPreventClose().then((value) {
      if (value) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    // Save app state & then close.
                    config.saveApplicationState().then((value) {
                      Navigator.of(context).pop();
                      windowManager.destroy();
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _selectProjectPath() {
    FilePicker.platform.getDirectoryPath(dialogTitle: 'Select project path.').then((value) {
      if (value != null) {
        config.videoProject.projectPath = value;
        _projectPathController.text = value;
      }
    });
  }

  void _importProjectFile(final BuildContext context) {
    _loadFile(() {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Loaded config for ${config.videoProject.projectName}'),
      ));

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
          (Route<dynamic> route) => false);
    });
  }

  /// Pushes a new page
  void _navigateToPage(final BuildContext context, final StatefulWidget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  ///
  void _importFile(final Function(String) newPath) {
    FilePicker.platform.pickFiles(allowMultiple: false, dialogTitle: 'Pick file').then((value) {
      if (value != null) {
        newPath.call(value.files[0].path!);

        setState(() {});
      }
    });
  }

  void _saveProject(final BuildContext context) {
    config.saveApplicationState();
    ScaffoldMessenger.of(context).showSnackBar(successSnackbar('Successfully saved the project!'));
  }

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

  void _showCustomMenu(
      final TimeStamp timeStamp, final BuildContext context, final PointerDownEvent event) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay == null || event.buttons != kSecondaryButton) {
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        event.position.dx,
        event.position.dy,
        overlay.size.width - event.position.dx,
        overlay.size.height - event.position.dy,
      ),
      items: [
        PopupMenuItem(
          child: const Text('See clip'),
          onTap: () => _navigateToPage(
            context,
            ClipAdjust(
              videoClip: VideoClip(timeStamp, clipLength: const Duration(seconds: 20)),
            ),
          ),
        ),
        PopupMenuItem(
          child: const Text('Remove clip'),
          onTap: () {}, //TODO: remove clip callback
        ),
        PopupMenuItem(
          child: const Text('Export'),
          onTap: () => _exportSingleSegment(timeStamp),
        )
        //TODO: Clip length menu
      ],
    );
  }

  void _exportSingleSegment(final TimeStamp timeStamp) async {
    final int index = config.config.timeStamps.indexOf(timeStamp);

    final ProgressDialog dialog = ProgressDialog(context: context);
    dialog.show(max: index, msg: 'Exporting segment');
    await exportSegment(timeStamp, 20);

    dialog.update(value: index, msg: 'Exporting segment ${index + 1}');
    dialog.close();
  }

  void _exportSegments(final double segmentLength) async {
    final ProgressDialog dialog = ProgressDialog(context: context);

    dialog.show(max: config.config.timeStamps.length, msg: 'Exporting segments');
    await exportSegments(segmentLength);
    dialog.close();
  }

  void _showExportSegmentDialoge() {
    showDialog(
      context: context,
      builder: (context) {
        double segmentLength = 0;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            actions: [
              TextButton(
                onPressed: () => _exportSegments(segmentLength),
                style: textButtonStyle(context),
                child: const Text('Export'),
              )
            ],
            title: const Text('Export clips'),
            content: Column(
              children: [
                const Text(
                    'The duration one segment is equal to in seconds. 0 = the length between the beats'),
                Slider(
                  value: segmentLength,
                  max: 40,
                  min: 0,
                  label: segmentLength.round().toString(),
                  divisions: 40,
                  onChanged: (value) {
                    setState(() {
                      segmentLength = value;
                    });
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  List<Widget> appBarTrailing(final BuildContext context) {
    return [
      TextButton(
        onPressed: () => _navigateToPage(context, const SettingsPage()),
        child: const Text('Settings'),
      ),
      TextButton(
        onPressed: () => _importProjectFile(context),
        child: const Text('Import'),
      ),
      TextButton(
        onPressed: () => _saveProject(context),
        child: const Text('Save'),
      )
    ];
  }

  Widget _buildProjectName() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: EditableText(
        style: Theme.of(context).textTheme.headlineSmall!,
        controller: _projectNameController,
        focusNode: FocusNode(),
        cursorColor: Colors.blueGrey,
        backgroundCursorColor: Colors.white,
        onChanged: (value) => config.videoProject.projectName = value,
      ),
    );
  }

  Widget _buildAudioColumn(final BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0), // inner padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Audio',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            Text(config.videoProject.config.audioPath),
            const Padding(padding: EdgeInsets.all(10)),
            IconButton(
              onPressed: () => _importFile((p0) => config.videoProject.config.audioPath = p0),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
            const Padding(padding: EdgeInsets.all(5)),
            TextButton(
              onPressed: () => _navigateToPage(context, const AudioAnalysis()),
              style: textButtonStyle(context),
              child: const Text('Analyse Audio'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoColumn(final BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Video',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            Text(config.videoProject.config.videoPath),
            const Padding(padding: EdgeInsets.all(10)),
            IconButton(
              onPressed: () => _importFile((p0) => config.videoProject.config.videoPath = p0),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
            const Padding(padding: EdgeInsets.all(5)),
            TextButton(
              onPressed: () => _navigateToPage(context, const VideoPlayer()),
              style: textButtonStyle(context),
              child: const Text('Select Clips'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipsGrid(final BuildContext context) {
    return GridView.builder(
      itemCount: config.videoProject.config.timeStamps.length,
      itemBuilder: (context, index) {
        final TimeStamp timeStamp = config.videoProject.config.timeStamps[index];

        return Card(
          elevation: 5,
          child: Listener(
              onPointerDown: (event) => _showCustomMenu(timeStamp, context, event),
              child: TimeStampCard(timeStamp: timeStamp)),
        );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildClipsColumn(final BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            children: [
              Text(
                'Clips',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Expanded(child: _buildClipsGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectPathRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: TextFormField(
            controller: _projectPathController,
            decoration: const InputDecoration(
              labelText: 'Project path',
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        IconButton(
          onPressed: () => _selectProjectPath(),
          icon: const Icon(Icons.file_open),
          style: iconButtonStyle(context),
        ),
      ],
    );
  }

  Widget _buildProjectColumn() {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: _buildProjectPathRow(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: _buildProjectName(),
        actions: appBarTrailing(context),
      ),
      body: Center(
        child: Row(
          children: [
            SizedBox(
              width: context.mediaSize.width / 3,
              height: context.mediaSize.height * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProjectColumn(),
                  _buildAudioColumn(context),
                  _buildVideoColumn(context),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () => _showExportSegmentDialoge(),
                      style: textButtonStyle(context),
                      child: const Text('Export'),
                    ),
                  )
                ],
              ),
            ),
            _buildClipsColumn(context)
          ],
        ),
      ),
    );
  }
}
