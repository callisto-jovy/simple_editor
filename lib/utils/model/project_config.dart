import 'package:jni/jni.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart' as backend;
import 'package:video_editor/utils/model/filter_wrapper.dart';
import 'package:video_editor/utils/model/timestamp.dart';

class ProjectConfig {
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
  final Map<String, bool> editingOptions = backend.FlutterWrapper.getEditingFlags()
      .map((key, value) => MapEntry(key.toDartString(releaseOriginal: true), false));

  ProjectConfig();

  /// [Map] with all the backend's filters. Key: [String] (filter's name). Value [FilterWrapper]
  /// helper class to store the filter's value & whether it should be enabled.
  /// Makes a call to the backend through JNI and maps the result.
  final List<FilterWrapper> filters = backend.FlutterWrapper.getFilters()
      .map((element) => FilterWrapper.fromBackend(element))
      .toList();

  ProjectConfig.fromJson(final Map<String, dynamic> json) {
    timeStamps.clear();

    videoPath = json['source_video'];
    audioPath = json['source_audio'];
    peakThreshold = json['peak_threshold'];
    msThreshold = json['ms_threshold'];
    introStart = json['intro_start'] == -1 ? null : Duration(microseconds: json['intro_start']);
    introEnd = json['intro_end'] == -1 ? null : Duration(microseconds: json['intro_end']);
    json['time_stamps'].forEach((v) => timeStamps.add(TimeStamp.fromJson(v)));
    json['editing_flags'].forEach((key, value) => editingOptions[key] = value);
    json['filters'].forEach(
      (v) => filters.where((element) => element.name == v['name']).forEach((element) {
        v['values'].forEach((k, v) => element.values[k] = v);
        element.enabled = v['enabled'];
      }),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_video': videoPath,
        'source_audio': audioPath,
        'peak_threshold': peakThreshold,
        'ms_threshold': msThreshold,
        'intro_start': introStart == null ? -1 : introStart!.inMicroseconds,
        'intro_end': introEnd == null ? -1 : introEnd!.inMicroseconds,
        'time_stamps': timeStamps,
        'editing_flags': editingOptions,
        'filters': filters.toList(),
      };

  Map<String, dynamic> editorConfig() {
    final JList<JDouble> beatTimes = backend.AudioAnalyser.analyseBeats(
        JString.fromString(audioPath), peakThreshold, msThreshold);

    return {
      'source_video': videoPath,
      'source_audio': audioPath,
      'peak_threshold': peakThreshold,
      'ms_threshold': msThreshold,
      'working_path': config.videoProject.workingDirectory.path,
      'output_path': path.join(
          config.videoProject.projectPath, '${path.basenameWithoutExtension(videoPath)}.mp4'),
      //TODO: Request file picker for filename and path.
      'editor_state': {
        'intro_start': introStart == null ? -1 : introStart!.inMicroseconds,
        'intro_end': introEnd == null ? -1 : introEnd!.inMicroseconds,
        'time_stamps': timeStamps.map((e) => e.start.inMicroseconds).toList(),
        'beat_times': beatTimes.map((e) => e.doubleValue(releaseOriginal: true)).toList(),
        'editing_flags': editingOptions,
        'filters': filters
            .where((element) => element.enabled == true)
            .map((e) => {'name': e.name, 'values': e.values})
            .toList(),
      },
    };
  }
}
