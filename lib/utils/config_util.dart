import 'dart:convert';
import 'dart:io';

import 'package:jni/jni.dart';

import 'fast_edits_backend.dart';

String audioPath = '';
String videoPath = '';

double peakThreshold = 0;
double msThreshold = 0;

Duration? introStart, introEnd;

final List<Duration> timeStamps = [];

const JsonEncoder encoder = JsonEncoder.withIndent('  ');

final Map<String, bool> editingOptions = {
  'WRITE_HDR_OPTIONS': true,
  'BEST_QUALITY': true,
  'SHUFFLE_SEQUENCES': false,
  'INTERPOLATE_FRAMES': false,
  'FADE_TRANSITION': false,
  'ZOOM_IN': false,
  'FADE_OUT_VIDEO': true,
};

String toJson() {
  final JList<JDouble> beatTimes =
      AudioAnalyser.analyseBeats(JString.fromString(audioPath), peakThreshold, msThreshold);

  final json = {
    'source_video': videoPath,
    'source_audio': audioPath,
    'peak_threshold': peakThreshold,
    'ms_threshold': msThreshold,
    'editor_state': {
      'intro_start': introStart == null ? -1 : introStart!.inMicroseconds,
      'intro_end': introEnd == null ? -1 : introEnd!.inMicroseconds,
      'time_stamps': timeStamps.map((e) => e.inMicroseconds).toList(),
      'beat_times': beatTimes.map((e) => e.doubleValue(releaseOriginal: true)).toList(),
      'editing_flags': editingOptions
    }
  };
  return encoder.convert(json);
}

void exportFile({File? file}) {
  file ??= File('saved_state.json');

  file.writeAsString(toJson());
}

void importFile({String? path}) {
  if (path == null || path.isEmpty) return;

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
  micros.map((e) => Duration(microseconds: e)).forEach((element) {
    timeStamps.add(element);
  });
}
