import 'package:jni/jni.dart';
import 'package:video_editor/utils/easy_edits_backend.dart' as backend;

import 'config.dart';

/// Calls the backend to make sure that the frame exporting can take place.
/// Should only be called if the [videoProject] is registered, the video path is non-null and the working directory is non-null as well.
void startFrameExport() {
  backend.FlutterWrapper.initFrameExport(
    JString.fromString(config.videoPath),
    JString.fromString(videoProject.workingDirectory.path),
  );
}



/// Calls the backend & tells it to release all allocated resources which are associated with the current frame exporting instance.
void stopFrameExport() {
  backend.FlutterWrapper.stopFrameExport();
}
