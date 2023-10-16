import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/widgets/easy_edits_app_bar.dart';
import 'package:video_editor/widgets/snackbars.dart';
import 'package:video_editor/widgets/styles.dart';

class MainProjectPage extends StatefulWidget {
  const MainProjectPage({super.key});

  @override
  State<MainProjectPage> createState() => _MainProjectPageState();
}

class _MainProjectPageState extends State<MainProjectPage> {
  /// [TextEditingController] which controls the video path
  final TextEditingController _videoPathController =
      TextEditingController(text: config.videoProject.config.videoPath);

  /// [TextEditingController] which controls the audio path
  final TextEditingController _audioPathController =
      TextEditingController(text: config.videoProject.config.audioPath);

  /// [TextEditingController] which controls the project name
  final TextEditingController _projectNameController =
      TextEditingController(text: config.videoProject.projectName);

  final TextEditingController _projectPathController =
      TextEditingController(text: config.videoProject.projectPath);

  @override
  void dispose() {
    super.dispose();
    _videoPathController.dispose();
    _audioPathController.dispose();
    _projectPathController.dispose();
    _projectNameController.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  /// Pushes the video player page
  void _navigateToVideo(final BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoPlayer(),
      ),
    );
  }

  /// Pushes the audio analysis page
  void _navigateToAudio(final BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AudioAnalysis(),
      ),
    );
  }

  void _importFile(final Function(String) newPath) {
    FilePicker.platform.pickFiles(allowMultiple: false, dialogTitle: 'Pick file').then((value) {
      if (value != null) {
        newPath.call(value.files[0].path!);
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

  void _saveProject(final BuildContext context) {
    config.saveApplicationState();
    ScaffoldMessenger.of(context).showSnackBar(successSnackbar('Successfully saved the project!'));
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

  Widget _buildAudioRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: TextFormField(
            controller: _audioPathController,
            decoration: const InputDecoration(
              labelText: 'Audio path',
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        IconButton(
          onPressed: () => _importFile((p0) => config.videoProject.config.audioPath = p0),
          icon: const Icon(Icons.file_open),
          style: iconButtonStyle(context),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        TextButton(
            onPressed: () => _navigateToAudio(context),
            style: textButtonStyle(context),
            child: const Text('Edit'))
      ],
    );
  }

  Widget _buildVideoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: TextFormField(
            controller: _videoPathController,
            decoration: const InputDecoration(
              labelText: 'Video path',
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        IconButton(
          onPressed: () => _importFile((p0) => config.videoProject.config.videoPath = p0),
          icon: const Icon(Icons.file_open),
          style: iconButtonStyle(context),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        TextButton(
          onPressed: () => _navigateToVideo(context),
          style: textButtonStyle(context),
          child: const Text('Edit'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mainAppBar(context),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditableText(
                style: Theme.of(context).textTheme.headlineSmall!,
                controller: _projectNameController,
                focusNode: FocusNode(),
                cursorColor: Colors.blueGrey,
                backgroundCursorColor: Colors.white,
                onChanged: (value) => config.videoProject.projectName = value,
              ),
              _buildVideoRow(),
              const Padding(padding: EdgeInsets.all(15)),
              _buildAudioRow(),
              const Padding(padding: EdgeInsets.all(15)),
              _buildProjectPathRow(),
              const Padding(padding: EdgeInsets.all(15)),
              TextButton(
                onPressed: () => _saveProject(context),
                style: textButtonStyle(context),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
