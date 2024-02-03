import 'dart:io';

import 'package:video_editor/utils/audio/audio_util.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:wav/wav_file.dart';

/// [List] of the audio file's audio samples.
final List<double> samples = [];

/// The length of the supplied input audio in milliseconds as a [double]
double audioLength = 10000;

/// Starts to load the audio from the config video path.
/// Calculates the length in milliseconds, chops the samples & adds them to the [List]
Future<void> loadBackgroundAudio() async {
  if (videoProject.config.audioPath.isEmpty || !File(videoProject.config.audioPath).existsSync()) {
    return;
  }

  // Read the wav file from the audio path.
  final Wav wav = await Wav.readFile(videoProject.config.audioPath);
  // Chop the samples
  final List<double> samplesData = chopSamples(wav.toMono(), wav.samplesPerSecond);

  // Clear the previous samples if not empty.
  if (samplesData.isNotEmpty) {
    samples.clear();
  }
  samples.addAll(samplesData);

  /// Total length / spp = length in seconds
  audioLength = ((wav.toMono().length / wav.samplesPerSecond) * 1000);
}
