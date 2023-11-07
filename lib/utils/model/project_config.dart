import 'package:video_editor/utils/model/audio_data.dart';
import 'package:video_editor/utils/easy_edits_backend.dart' as backend;
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:video_editor/utils/model/filter_wrapper.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';

class ProjectConfig {
  /// No parameters.
  ProjectConfig();

  /// The [String] config audio path for the edit
  String audioPath = '';

  /// The [String] config video path for the edit
  String videoPath = '';

  /// [String] path to the latest generated preview.
  String previewPath = '';

  /// [double] for the peak threshold
  double peakThreshold = 0;

  /// [double] for the millisecond threshold between onsets
  double msThreshold = 0;

  /// Nullable [Duration], the intro start and end. If not set, it will just be ignored.
  Duration? introStart, introEnd;

  /// [List] will all the set timestamps
  final List<TimeStamp> timeStamps = [];

  /// [List] with the time stamps of onsets in the audio file.
  /// This list is transformed into the differences between the timestamps.
  final List<double> beatStamps = [];

  /// [List] of all the video clips in the editor.
  final List<VideoClip> videoClips = [];

  final List<AudioClip> audioClips = [];

  /// [Map] of generated clip previews. Contains the paths to the previews.
  /// Key: a [VideoClip] that a preview was generated for.
  /// Value: the path to the generated preview.
  final Map<String, String> generatedPreviews = {};

  /// [Map] of editing options. Key: the flag's key. Value: Whether the flag is to be enabled.
  final Map<String, bool> editingOptions = backend.FlutterWrapper.getEditingFlags()
      .map((key, value) => MapEntry(key.toDartString(releaseOriginal: true), false));

  /// [Map] with all the backend's filters. Key: [String] (filter's name). Value [FilterWrapper]
  /// helper class to store the filter's value & whether it should be enabled.
  /// Makes a call to the backend through JNI and maps the result.
  final List<FilterWrapper> filters = backend.FlutterWrapper.getFilters()
      .map((element) => FilterWrapper.fromBackend(element))
      .toList();

  /// Converts the [List] of timestamps into a [List] of the time between the stamps.
  List<double> timeBetweenBeats() {
    final List<double> timeBetweenBeats = [];

    // Calculate the difference between the timestamps.
    // this is the time one beat lasts.
    double lastBeat = 0;

    for (int i = 0; i < beatStamps.length - 1; i++) {
      final double timeStamp = beatStamps[i];
      final double diff = timeStamp - lastBeat;
      timeBetweenBeats.add(diff);
      lastBeat = timeStamp;
    }

    timeBetweenBeats.add(audioLength - lastBeat);

    return timeBetweenBeats;
  }

  ProjectConfig.fromJson(final Map<String, dynamic> json) {
    /// Clear all the lists beforehand if the user loads another project.
    timeStamps.clear();
    videoClips.clear();
    beatStamps.clear();

    videoPath = json['source_video'];
    audioPath = json['source_audio'];
    previewPath = json['preview_path'];
    peakThreshold = json['peak_threshold'];
    msThreshold = json['ms_threshold'];
    introStart = json['intro_start'] == -1 ? null : Duration(microseconds: json['intro_start']);
    introEnd = json['intro_end'] == -1 ? null : Duration(microseconds: json['intro_end']);
    json['clip_previews'].forEach((key, value) => generatedPreviews[key] = value);
    json['time_stamps'].forEach((v) => timeStamps.add(TimeStamp.fromJson(v)));
    json['beat_times'].forEach((v) => beatStamps.add(v));
    json['editing_flags'].forEach((key, value) => editingOptions[key] = value);
    json['filters'].forEach(
      (v) => filters.where((element) => element.name == v['name']).forEach((element) {
        v['values'].forEach((k, v) => element.values[k] = v);
        element.enabled = v['enabled'];
      }),
    );
    json['video_clips'].forEach((v) => videoClips.add(VideoClip.fromJson(v)));
  }

  Map<String, dynamic> toJson() => {
        'source_video': videoPath,
        'source_audio': audioPath,
        'preview_path': previewPath,
        'peak_threshold': peakThreshold,
        'ms_threshold': msThreshold,
        'intro_start': introStart == null ? -1 : introStart!.inMicroseconds,
        'intro_end': introEnd == null ? -1 : introEnd!.inMicroseconds,
        'time_stamps': timeStamps,
        'beat_times': beatStamps,
        'video_clips': videoClips,
        'editing_flags': editingOptions,
        'clip_previews': generatedPreviews,
        'filters': filters.toList(),
      };
}
