import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:video_editor/utils/model/timestamp.dart';

import 'easy_edits_backend.dart';

String audioPath = '';
String videoPath = '';

double peakThreshold = 0;
double msThreshold = 0;

Duration? introStart, introEnd;

final List<TimeStamp> timeStamps = [];

const JsonEncoder encoder = JsonEncoder.withIndent('  ');

final Map<String, bool> editingOptions = {
  'WRITE_HDR_OPTIONS': true,
  'BEST_QUALITY': true,
  'SHUFFLE_SEQUENCES': false,
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
      'time_stamps': timeStamps.map((e) => e.start.inMicroseconds).toList(),
      'beat_times': beatTimes.map((e) => e.doubleValue(releaseOriginal: true)).toList(),
      'editing_flags': editingOptions,
      'filters': [], // TODO: Enable & configure filters in the ui
    },
    'thumbnails': timeStamps.map((e) => base64Encode(Uint8List.view(e.startFrame!.buffer))).toList()
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
