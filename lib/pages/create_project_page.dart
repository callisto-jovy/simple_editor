import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/pages/main_project_page.dart';
import 'package:video_editor/utils/config.dart' as config;
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
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectPathController = TextEditingController();

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectPathController.dispose();
    super.dispose();
  }

  void _selectPath() async {
    final String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Project path',
    );

    if (result != null) {
      _projectPathController.text = result;
    }
  }

  void _createProject(final BuildContext context) async {
    if (_projectNameController.text.isNotEmpty && _projectPathController.text.isNotEmpty) {
      config.videoProject = VideoProject(
        _projectPathController.text,
        projectName: _projectNameController.text,
        config: ProjectConfig(),
      );

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
          (Route<dynamic> route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('Project name or path is empty.'));
    }
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
              TextFormField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: TextFormField(
                      controller: _projectPathController,
                      decoration: const InputDecoration(
                        labelText: 'Project Path',
                      ),
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
              TextButton(
                style: textButtonStyle(context),
                onPressed: () => _createProject(context),
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
