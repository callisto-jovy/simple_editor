import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';
import 'package:path/path.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:wav/wav.dart';

class AudioData {
  final Wav wav;
  final String path;

  AudioData(this.wav, this.path);

  int get samplesPerSecond => wav.samplesPerSecond;

  static Future<AudioData> fromJson(final Map<String, dynamic> json) async {
    final String path = json['path'];
    final Wav wav = await Wav.readFile(path);

    return AudioData(wav, path);
  }

  Map<String, dynamic> toJson() => {'path': path};
}

/// Reduces a given [List] of audio samples to to a new [List] of total samples.
List<double> reduceSamples(final List<double> rawSamples, final int totalSamples) {
  final List<double> filteredData = [];
  // Change this value to number of audio samples you want.
  // Values between 256 and 1024 are good for showing [RectangleWaveform] and [SquigglyWaveform]
  // While the values above them are good for showing [PolygonWaveform]
  final double blockSize = rawSamples.length / totalSamples;

  for (int i = 0; i < totalSamples; i++) {
    final double blockStart = blockSize * i; // the location of the first sample in the block
    double sum = 0;
    for (int j = 0; j < blockSize; j++) {
      sum += rawSamples[(blockStart + j).toInt()]; // find the sum of all the samples in the block
    }
    // take the average of the block and add it to the filtered data
    filteredData.add((sum / blockSize)); // divide the sum by the block size to get the average
  }

  // Find the maximum in the filtered data
  final double maxNum = filteredData.reduce((a, b) => math.max(a.abs(), b.abs()));
  // 1/maxnum
  final double multiplier = math.pow(maxNum, -1).toDouble();
  // map the samples *1/maxnum
  final List<double> samples = filteredData.map<double>((e) => (e * multiplier)).toList();

  return samples;
}

/// Reads
Future<AudioData> readVideoFile(final String path) async {
  final String outputFile = join(dirname(path), '${basenameWithoutExtension(path)}.wav');

  if (File(outputFile).existsSync()) {
    return _readVideoSamples(outputFile);
  }

  // Convert the video's audio to a stereo wav file.
  final FfmpegCommand ffmpegCommand = FfmpegCommand.simple(outputFilepath: outputFile, inputs: [
    FfmpegInput.asset(path),
  ], args: [
    const CliArg(name: "ac", value: "2"),
    const CliArg(name: "vn"),
    const CliArg(name: "c:a", value: "pcm_u8"),
  ]);

  final Process process = await Ffmpeg().run(ffmpegCommand);

  process.stdout.listen((event) {
    print(utf8.decode(event));
  });
  process.stderr.listen((event) {
    print(utf8.decode(event));
  });

  final int exitCode = await process.exitCode; //Await the termination

  return _readVideoSamples(outputFile);
}

Future<AudioData> _readVideoSamples(final String path) async {
  final Wav wav = await Wav.readFile(path);

  final AudioData data = AudioData(wav, path);

  return data;
}

List<double> readSamplesForClip(final AudioClip audioClip) {
  // We just need a rough estimate of the samples starting position for our waveform.
  // NOTE: no bounds checking for the timestamp is necessary, as the timestamp has to be in the in the video's length.
  final int requiredSamples = audioClip.timeStamp.inSeconds * config.audioData.samplesPerSecond;

  final int endSamples =
      requiredSamples + (audioClip.clipLength.inSeconds * config.audioData.samplesPerSecond);

  if(endSamples > config.audioData.wav.duration) {
    return List<double>.empty();
  }

  final Float64List rawSamples = config.audioData.wav.toMono();
  return reduceSamples(rawSamples.sublist(requiredSamples, endSamples), 124);
}
