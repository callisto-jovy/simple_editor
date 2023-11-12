import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';
import 'package:path/path.dart';
import 'package:video_editor/utils/config/config.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:wav/bytes_reader.dart';
import 'package:wav/util.dart';
import 'package:wav/wav.dart';

class AudioData {
  final String path;

  AudioData(this.path);

  AudioData.fromJson(final Map<String, dynamic> json) : path = json['path'];

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
  return AudioData(path);
}

const _kFormatSize = 16;
const _kFactSize = 4;
const _kFileSizeWithoutData = 36;
const _kFloatFmtExtraSize = 12;
const _kPCM = 1;
const _kFloat = 3;
const _kStrRiff = 'RIFF';
const _kStrWave = 'WAVE';
const _kStrFmt = 'fmt ';
const _kStrData = 'data';
const _kStrFact = 'fact';

List<double> readSamplesForClip(final AudioClip audioClip) {
  // We just need a rough estimate of the samples starting position for our waveform.
  // NOTE: no bounds checking for the timestamp is necessary, as the timestamp has to be in the in the video's length.

  var bytes = File(config.audioData.path).readAsBytesSync();

  // Utils for reading.
  var byteReader = BytesReader(bytes)
    ..assertString(_kStrRiff)
    ..readUint32() // File size.
    ..assertString(_kStrWave)
    ..findChunk(_kStrFmt);

  final int fmtSize = roundUpToEven(byteReader.readUint32());
  final int formatCode = byteReader.readUint16();
  final int numChannels = byteReader.readUint16();
  final int samplesPerSecond = byteReader.readUint32();
  byteReader.readUint32(); // Bytes per second.
  final int bytesPerSampleAllChannels = byteReader.readUint16();
  final int bitsPerSample = byteReader.readUint16();
  if (fmtSize > _kFormatSize) byteReader.skip(fmtSize - _kFormatSize);

  byteReader.findChunk(_kStrData);
  final int dataSize = byteReader.readUint32();
  final int numSamples = dataSize ~/ bytesPerSampleAllChannels;

  final WavFormat format = _getFormat(formatCode, bitsPerSample);

  final int sampleStart = audioClip.timeStamp.inSeconds * samplesPerSecond;
  final int sampleEnd = sampleStart + (audioClip.clipLength.inSeconds * samplesPerSecond);

  // Skip to the position
  byteReader.skip(format.bytesPerSample * sampleStart);

  // Read samples.
  final SampleReader readSample = byteReader.getSampleReader(format);

  final int sampleBytes = sampleEnd * format.bytesPerSample;
  final Float64List rawSamples = Float64List(sampleBytes);

  for (int i = 0; i < sampleBytes; ++i) {
    rawSamples[i] = readSample();

    // for (int j = 0; j < numChannels; ++j) {
    // rawSamples[i] = (readSample());
    //}
    // rawSamples[i] /= numChannels;
  }

  final List<double> reducedSamples = reduceSamples(rawSamples, samplesPerSecond);
  return reducedSamples;
}

WavFormat _getFormat(int formatCode, int bitsPerSample) {
  if (formatCode == _kPCM) {
    if (bitsPerSample == 8) return WavFormat.pcm8bit;
    if (bitsPerSample == 16) return WavFormat.pcm16bit;
    if (bitsPerSample == 24) return WavFormat.pcm24bit;
    if (bitsPerSample == 32) return WavFormat.pcm32bit;
  } else if (formatCode == _kFloat) {
    if (bitsPerSample == 32) return WavFormat.float32;
    if (bitsPerSample == 64) return WavFormat.float64;
  }
  throw FormatException('Unsupported format: $formatCode, $bitsPerSample');
}
