import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart' as backend;
import 'package:video_editor/utils/model/filter_wrapper.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:wav/wav_file.dart';

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
  Future<List<double>> timeBetweenBeats() async {
    final List<double> timeBetweenBeats = [];

    final Wav wav = await Wav.readFile(config.videoProject.config.audioPath);

    /// Total length / spp = length in seconds
    final double lengthInMillis = ((wav.toMono().length / wav.samplesPerSecond) * 1000);

    // Calculate the difference between the timestamps.
    // this is the time one beat lasts.
    double lastBeat = 0;

    for(int i = 0; i < beatStamps.length - 1; i++) {
      final double timeStamp = beatStamps[i];
      final double diff = timeStamp - lastBeat;
      timeBetweenBeats.add(diff);
      lastBeat = timeStamp;
    }

    print(lengthInMillis - lastBeat);

    timeBetweenBeats.add(lengthInMillis - lastBeat);

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

  /// Converts the project's state into a json format which the Java-backend can understand.
  /// This [Map] stores the most important information in order to configure the editor.
  Future<Map<String, dynamic>> editorConfig() async {
    final List<double> beatTimes = await timeBetweenBeats();

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
        'video_clips': videoClips.isEmpty
            ? timeStamps
                .asMap()
                .map((key, value) => MapEntry(key, {
                      'time_stamp': value.start.inMicroseconds,
                      'mute_audio': true,
                      'clip_length': beatTimes[key] // TODO: Figure out, whether this works.
                    }))
                .values
                .toList()
            : videoClips
                .map((e) => {
                      'time_stamp': e.timeStamp.start.inMicroseconds,
                      'mute_audio': e.audioMuted,
                      'clip_length': e.clipLength.inMilliseconds
                    })
                .toList(), // NOTE:: breaking change for older backend versions.
        'editing_flags': editingOptions,
        'filters': filters
            .where((element) => element.enabled)
            .map((e) => {'name': e.name, 'values': e.values})
            .toList(),
      },
    };
  }

  Map<String, dynamic> previewJson(final VideoClip clip) {
    return {
      'source_video': videoPath,
      'working_path': config.videoProject.workingDirectory.path,
      'clip': {
        'time_stamp': clip.timeStamp.start.inMicroseconds,
        'mute_audio': clip.audioMuted,
        'clip_length': clip.clipLength.inMilliseconds
      },
      'filters': filters
          .where((element) => element.enabled)
          .map((e) => {'name': e.name, 'values': e.values})
          .toList(),
      'editing_flags': editingOptions,
    };
  }

  Map<String, dynamic> previewEdit(final List<String> previewPaths) {
    return {
      'source_video': videoPath,
      'source_audio': audioPath,
      'working_path': config.videoProject.workingDirectory.path,
      'filters': filters
          .where((element) => element.enabled)
          .map((e) => {'name': e.name, 'values': e.values})
          .toList(),
      'editing_flags': editingOptions,
      'previews': previewPaths,
    };
  }
}
