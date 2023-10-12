import 'package:mime/mime.dart';

bool isFileAudio(final String path) {
  return path.isNotEmpty &&
      (lookupMimeType(path) == 'audio/wav'  || lookupMimeType(path) == 'audio/x-wav');
}

bool isFileVideo(final String path) {
  return path.isNotEmpty && lookupMimeType(path)?.split('/')[0] == 'video';
}
