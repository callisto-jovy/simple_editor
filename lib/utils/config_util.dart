import 'dart:convert';
import 'dart:io';

import 'package:jni/jni.dart';

import '../audio/tarsosdsp.dart';

String audioPath = '';
String videoPath = '';

double peakThreshold = 0;
double msThreshold = 0;

Duration? introStart, introEnd;

final List<Duration> timeStamps = [];

const JsonEncoder encoder = JsonEncoder.withIndent('  ');


void exportFile({File? file}) {
  file ??= File('saved_state.json');

  final JList<JDouble> beatTimes = AudioAnalyser.analyseBeats(
      JString.fromString(audioPath), peakThreshold, msThreshold);


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
    }
  };
  file.writeAsString(encoder.convert(json));
}
