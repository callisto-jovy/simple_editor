import 'package:video_editor/utils/audio_data_loader.dart';
import 'package:video_editor/utils/config.dart';
import 'package:wav/wav_file.dart';

/// [List] of the audio file's audio samples.
final List<double> samples = [];

//
double audioLength = 10000;

/// Starts to load the audio from the config video path.
/// Calculates the length in milliseconds, chops the samples & adds them to the [List]
Future<void> loadAudioData() async {
  if (videoProject.config.audioPath.isEmpty) {
    return;
  }

  final Wav wav = await Wav.readFile(videoProject.config.audioPath);

  final List<double> samplesData = chopSamples(wav.toMono(), wav.samplesPerSecond);

  samples.clear();
  samples.addAll(samplesData);

  /// Total length / spp = length in seconds
  audioLength = ((wav.toMono().length / wav.samplesPerSecond) * 1000);
}
