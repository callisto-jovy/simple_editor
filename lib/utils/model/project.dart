import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:video_editor/utils/model/project_config.dart';

class VideoProject {
  /// The applications output directory. The segments are exported there (& optionally edited together)
  Directory workingDirectory = Directory('editor_out')..createSync();

  String projectName;
  String _projectPath = '';
  final ProjectConfig config;

  VideoProject(this._projectPath, {required this.projectName, required this.config});

  VideoProject.fromJson(final Map<String, dynamic> json)
      : projectName = json['project_name'],
        _projectPath = json['project_path'],
        config = ProjectConfig.fromJson(json['config']);

  Map<String, dynamic> toJson(final String version) => {
        'version': version,
        'project_name': projectName,
        'project_path': _projectPath,
        'config': config.toJson(),
      };

  set projectPath(String value) {
    _projectPath = value;
    workingDirectory = Directory(path.join(_projectPath, 'editor_out'));
  }

  String get projectPath => _projectPath;
}
