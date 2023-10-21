import 'package:flexible_slider/flexible_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:jni/jni.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/audio_data_loader.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/widgets/styles.dart';
import 'package:video_editor/widgets/time_stamp_painer.dart';
import 'package:wav/wav_file.dart';

class AudioAnalysis extends StatefulWidget {
  const AudioAnalysis({super.key});

  @override
  State<AudioAnalysis> createState() => _AudioAnalysisState();
}

class _AudioAnalysisState extends State<AudioAnalysis> {
  final List<double> samples = [];
  double lengthInMillis = 0;

  final List<double> timeStamps = [];

  final GlobalKey _paintKey = GlobalKey();

  Offset? _hitOffset;

  /// Starts to load the audio from the config video path.
  /// Calculates the length in milliseconds, chops the samples & adds them to the [List]
  Future<void> loadAudio() async {
    final Wav wav = await Wav.readFile(config.videoProject.config.audioPath);

    /// Total length / spp = length in seconds
    lengthInMillis = ((wav.toMono().length / wav.samplesPerSecond) * 1000);

    final samplesData = chopSamples(wav.toMono(), wav.samplesPerSecond);

    setState(() {
      samples.clear();
      samples.addAll(samplesData);
    });
  }

  Future<void> _executeTimeStamps() async {
    final JList<JDouble> doubles = AudioAnalyser.analyseStamps(
        JString.fromString(config.videoProject.config.audioPath),
        config.videoProject.config.peakThreshold,
        config.videoProject.config.msThreshold);

    setState(() {
      timeStamps.clear();
      for (var element in doubles) {
        timeStamps.add(element.doubleValue(releaseOriginal: true));
      }
    });
  }

  void _addTimeStampForRemoval(final List<double> timeStamp) {
    for (final double element in timeStamp) {
      timeStamps.remove(element);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    _hitOffset = null;
  }

  @override
  void initState() {
    super.initState();
    loadAudio();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(path.basename(config.videoProject.config.audioPath)),
      ),
      body: Column(children: [
        const Padding(padding: EdgeInsets.all(25)),
        Text('Total cuts: ${timeStamps.length}'),
        const Padding(padding: EdgeInsets.all(25)),
        FlexibleSlider(
          onValueChanged: (p0) => config.videoProject.config.peakThreshold = p0,
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
          onValueChanged: (p0) => config.videoProject.config.msThreshold = p0,
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
        const Padding(padding: EdgeInsets.all(25)),
        Flexible(
          child: Listener(
            onPointerUp: (event) {
              final RenderBox? referenceBox =
                  _paintKey.currentContext?.findRenderObject() as RenderBox?;

              if (referenceBox == null) return;

              final Offset offset = event.localPosition;

              setState(() {
                _hitOffset = offset;
              });
            },
            child: Stack(
              children: [
                RepaintBoundary(
                  child: PolygonWaveform(
                    samples: samples,
                    height: size.height * 0.5,
                    width: size.width * 0.95,
                  ),
                ),
                CustomPaint(
                  key: _paintKey,
                  size: Size(
                    size.width * 0.95,
                    size.height * 0.5,
                  ),
                  foregroundPainter: TimeStampPainter(
                    timeStamps: timeStamps,
                    audioLength: lengthInMillis,
                    hitOffset: _hitOffset,
                    hitTimeStamp: _addTimeStampForRemoval,
                    newTimeStamp: (t) => WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        timeStamps.add(t);
                      });
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(25)),
        TextButton(
          onPressed: () => _executeTimeStamps(),
          style: textButtonStyle(context),
          child: const Text('Run analysis'),
        )
      ]),
    );
  }
}
