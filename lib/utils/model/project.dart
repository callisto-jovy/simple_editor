import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:video_editor/utils/model/project_config.dart';

class VideoProject {
  /// The applications output [Directory]. The segments are exported into that [Directory] (& optionally edited together)
  Directory workingDirectory = Directory('editor_out');

  /// [String] which holds the project's name.
  String projectName;

  /// private [String] which stores the project path.
  /// private, in order to overwrite the getter & setter, to ensure that the working directory is set.
  String _projectPath = '';

  /// Reference to the [ProjectConfig]
  final ProjectConfig config;

  /// Default constructor
  VideoProject(this._projectPath, {required this.projectName, required this.config}) {
    workingDirectory = Directory(path.join(_projectPath, 'editor_out'));
  }

  VideoProject.fromJson(final Map<String, dynamic> json)
      : projectName = json['project_name'],
        _projectPath = json['project_path'],
        config = ProjectConfig.fromJson(json['config']) {
    workingDirectory = Directory(path.join(_projectPath, 'editor_out'));
  }

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

  /// TODO: pass through some getters for the project config, in order to eliminate long calls
}
