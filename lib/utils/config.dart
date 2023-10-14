import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/model/filter_wrapper.dart';
import 'package:video_editor/utils/model/timestamp.dart';

import 'easy_edits_backend.dart';

/// The applications output directory. The segments are exported there (& optionally edited together)
Directory workingDirectory = Directory('editor_out')..createSync();

/// Makes sure that the [Directory] exists
Future<void> ensureOutExists() async {
  final bool exists = await workingDirectory.exists();
  if (!exists) {
    await workingDirectory.create();
  }
}

/// The applications [JsonEncoder] with a specified indent of two.
const JsonEncoder encoder = JsonEncoder.withIndent('  ');

/// The [String] config audio path for the edit
String audioPath = '';

/// The [String] config video path for the edit
String videoPath = '';

/// [double] for the peak threshold
double peakThreshold = 0;

/// [double] for the millisecond threshold between onsets
double msThreshold = 0;

/// Nullable [Duration], the intro start and end. If not set, it will just be ignored.
Duration? introStart, introEnd;

/// [List] will all the set timestamps
final List<TimeStamp> timeStamps = [];

/// [Map] of editing options. Key: the flag's key. Value: Whether the flag is to be enabled.
/// TODO: grab from the backend (see filters).
final Map<String, bool> editingOptions = {
  'WRITE_HDR_OPTIONS': true,
  'BEST_QUALITY': true,
  'SHUFFLE_SEQUENCES': false,
};

/// [Map] with all the backend's filters. Key: [String] (filter's name). Value [FilterWrapper]
/// helper class to store the filter's value & whether it should be enabled.
/// Makes a call to the backend through JNI and maps the result.
final Map<String, FilterWrapper> filters = FlutterWrapper.getFilterValueMap()
    .map((key, value) => MapEntry(
        key.toDartString(releaseOriginal: true), value.toDartString(releaseOriginal: true)))
    .map((key, value) => MapEntry(key, FilterWrapper(key, value, false)));

/// Creates a JSON [String] with all the app's state.
String toJson() {
  final JList<JDouble> beatTimes =
      AudioAnalyser.analyseBeats(JString.fromString(audioPath), peakThreshold, msThreshold);

  final json = {
    'source_video': videoPath,
    'source_audio': audioPath,
    'peak_threshold': peakThreshold,
    'ms_threshold': msThreshold,
    'working_path': workingDirectory.path, //TODO: Setting for path
    'output_path': 'edit_out.mp4', //TODO: Request for filename
    'editor_state': {
      'intro_start': introStart == null ? -1 : introStart!.inMicroseconds,
      'intro_end': introEnd == null ? -1 : introEnd!.inMicroseconds,
      'time_stamps': timeStamps.map((e) => e.start.inMicroseconds).toList(),
      'beat_times': beatTimes.map((e) => e.doubleValue(releaseOriginal: true)).toList(),
      'editing_flags': editingOptions,
      'filters': filters.entries
          .where((element) => element.value.enabled == true)
          .map((e) => {'name': e.key, 'value': e.value.value})
          .toList(),
    },
    'thumbnails': timeStamps
        .map(
            (e) => e.startFrame == null ? null : base64Encode(Uint8List.view(e.startFrame!.buffer)))
        .toList()
  };

  return encoder.convert(json);
}

void exportFile({File? file}) {
  file ??= File('saved_state.json');

  file.writeAsString(toJson());
}

void importFile({String? path}) {
  if (path == null || path.isEmpty) return;

  timeStamps.clear();

  final File file = File(path);
  dynamic json = jsonDecode(file.readAsStringSync());

  peakThreshold = json['peak_threshold'];
  msThreshold = json['ms_threshold'];
  videoPath = json['source_video'];
  audioPath = json['source_audio'];

  dynamic editorState = json['editor_state'];

  introStart = Duration(microseconds: editorState['intro_start']);
  introEnd = introStart = Duration(microseconds: editorState['intro_end']);

  final List<dynamic> micros = editorState['time_stamps'];
  final List<dynamic>? thumbnails = json['thumbnails'];

  for (int i = 0; i < micros.length; i++) {
    final Duration duration = Duration(microseconds: micros[i]);

    if (thumbnails != null && thumbnails.length > i && thumbnails[i] != null) {
      final String thumbnail = thumbnails[i];
      timeStamps.add(TimeStamp(duration, base64Decode(thumbnail).buffer.asByteData()));
    } else {
      timeStamps.add(TimeStamp(duration, null));
    }
  }
}
