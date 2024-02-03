import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config/project_config.dart';

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

  /// Reconstructs the object from a given [Map]
  VideoProject.fromJson(final Map<String, dynamic> json)
      : projectName = json['project_name'],
        _projectPath = json['project_path'],
        config = ProjectConfig.fromJson(json['config']) {
    workingDirectory = Directory(path.join(_projectPath, 'editor_out'));
  }

  /// Converts the project into a JSON [Map]
  Map<String, dynamic> toJson(final String version) => {
        'version': version,
        'project_name': projectName,
        'project_path': _projectPath,
        'config': config.toJson(),
      };

  /// Setter for the project path variable, as to make sure, that the output directory is created whenever the project path is set.
  set projectPath(String value) {
    _projectPath = value;
    workingDirectory = Directory(path.join(_projectPath, 'editor_out'));
  }

  /// getter for the project path, as the string is marked private.
  String get projectPath => _projectPath;
}
