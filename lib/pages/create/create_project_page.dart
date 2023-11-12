import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/pages/main_project_page.dart';
import 'package:video_editor/utils/audio/audio_data_util.dart';
import 'package:video_editor/utils/config/config.dart' as config;
import 'package:video_editor/utils/model/project.dart';
import 'package:video_editor/utils/model/project_config.dart';
import 'package:video_editor/widgets/snackbars.dart';
import 'package:video_editor/widgets/styles.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  /// [TextEditingController] that keeps track of the project name [TextFormField]
  final TextEditingController _projectNameController = TextEditingController();

  /// [TextEditingController] that keeps track of the project' path [TextFormField]
  final TextEditingController _projectPathController = TextEditingController();

  final TextEditingController _videoPathController = TextEditingController();

  final TextEditingController _audioPathController = TextEditingController();

  final MaterialStatesController _createButtonController = MaterialStatesController();

  bool _isVideoVisible = false;

  bool _isAudioVisible = false;

  bool _isProjectPathVisible = false;

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectPathController.dispose();
    _videoPathController.dispose();
    _audioPathController.dispose();
    _createButtonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Disable the create project controller
    _createButtonController.update(MaterialState.disabled, true);
  }

  ///
  Future<String?> _importFile() async {
    return FilePicker.platform
        .pickFiles(allowMultiple: false, dialogTitle: 'Pick file')
        .then((value) {
      return value?.files[0].path;
    });
  }

  void _selectVideoPath() async {
    final String? path = await _importFile();

    if (path != null) {
      _videoPathController.text = path;

      setState(() {
        _isAudioVisible = true; // Make the audio visible
      });
    }
  }

  void _selectAudioPath() async {
    final String? path = await _importFile();
    if (path != null) {
      _audioPathController.text = path;
      _createButtonController.update(MaterialState.disabled, false);
      setState(() {});
    }
  }

  void _selectPath() async {
    final String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Project path',
    );

    if (result != null) {
      _projectPathController.text = result;
      _isVideoVisible = true;
    }
  }

  void _createProject(final BuildContext context) async {
    if (_projectNameController.text.isNotEmpty && _projectPathController.text.isNotEmpty) {
      config.videoProject = VideoProject(
        _projectPathController.text,
        projectName: _projectNameController.text,
        config: ProjectConfig(),
      );

      // "Configure" the config.
      config.config.videoPath = _videoPathController.text;
      config.config.audioPath = _audioPathController.text;

      //TODO: Loading indicator.

      config.config.audioData = await readVideoFile(config.config.videoPath);

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
          (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('Project name or path is empty.'));
    }
  }

  Widget _buildVideoSelection() {
    return AnimatedOpacity(
      opacity: _isVideoVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Visibility(
        visible: _isVideoVisible,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              onPressed: () => _selectVideoPath(),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSelection() {
    return AnimatedOpacity(
      opacity: _isAudioVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Visibility(
        visible: _isAudioVisible,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              onPressed: () => _selectAudioPath(),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectPath() {
    return AnimatedOpacity(
      opacity: _isProjectPathVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Visibility(
        visible: _isProjectPathVisible,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: TextFormField(
                controller: _projectPathController,
                decoration: const InputDecoration(
                  labelText: 'Project Path',
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) _isVideoVisible = true;
                  });
                },
              ),
            ),
            const Padding(padding: EdgeInsets.all(10)),
            IconButton(
              onPressed: () => _selectPath(),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectNameField() {
    return TextFormField(
      controller: _projectNameController,
      decoration: const InputDecoration(
        labelText: 'Project Name',
      ),
      onChanged: (value) {
        setState(() {
          if (value.isNotEmpty) _isProjectPathVisible = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create a new project.'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProjectNameField(),
              _buildProjectPath(),
              _buildVideoSelection(),
              _buildAudioSelection(),
              TextButton(
                style: textButtonStyle(context),
                onPressed: () => _createProject(context),
                statesController: _createButtonController,
                child: const Text('Create'),
              )
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.all(15),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
