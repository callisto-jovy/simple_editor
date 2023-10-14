import 'package:flexible_slider/flexible_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:jni/jni.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/utils/audio_data_loader.dart';
import 'package:video_editor/widgets/time_stamp_painer.dart';
import 'package:wav/wav_file.dart';



class AudioAnalysis extends StatefulWidget {
  const AudioAnalysis({super.key});

  @override
  State<AudioAnalysis> createState() => _AudioAnalysisState();
}

class _AudioAnalysisState extends State<AudioAnalysis> {
  final List<double> samples = [];
  int lengthInMillis = 0;

  final List<double> timeStamps = [];

  Future<void> parseData() async {
    final Wav wav = await Wav.readFile(config.audioPath);

    lengthInMillis = ((wav.toMono().length / wav.samplesPerSecond) * 1000).round();

    final samplesData = chopSamples(wav.toMono(), wav.samplesPerSecond);

    setState(() {
      samples.clear();
      samples.addAll(samplesData);
    });
  }

  Future<void> executeTimeStamps() async {
    final JList<JDouble> doubles = AudioAnalyser.analyseStamps(
        JString.fromString(config.audioPath), config.peakThreshold, config.msThreshold);

    setState(() {
      timeStamps.clear();
      for (var element in doubles) {
        timeStamps.add(element.doubleValue(releaseOriginal: true));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    parseData();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(path.basename(config.audioPath)),
      ),
      body: Column(
        children: [
          Text('Total cuts: ${timeStamps.length}'),
          FlexibleSlider(
            onValueChanged: (p0) => config.peakThreshold = p0,
            max: 1,
            divisions: 100,
            fractionDigits: 4,
            textDecoration: const InputDecoration(
              label: Text("Peak Threshold"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),
          FlexibleSlider(
            onValueChanged: (p0) => config.msThreshold = p0,
            max: 2000,
            divisions: 100,
            fractionDigits: 4,
            textDecoration: const InputDecoration(
              label: Text("Ms Threshold"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),
          Stack(
            children: [
              PolygonWaveform(
                samples: samples,
                height: size.height * 0.3,
                width: size.width * 0.95,
              ),
              CustomPaint(
                size: Size(
                  size.width * 0.95,
                  size.height * 0.3,
                ),
                foregroundPainter: TimeStampPainter(timeStamps, lengthInMillis),
              ),
            ],
          ),
          TextButton(onPressed: () => executeTimeStamps(), child: const Text('Run analysis'))
        ]
            .map(
              (e) => Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: e,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
