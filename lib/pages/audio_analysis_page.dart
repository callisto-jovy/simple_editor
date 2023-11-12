import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flexible_slider/flexible_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:jni/jni.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/audio/audio_data_util.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart';
import 'package:video_editor/utils/beat_time_exporter.dart';
import 'package:video_editor/utils/config/config.dart' as config;
import 'package:video_editor/widgets/audio/audio_player_controls.dart';
import 'package:video_editor/widgets/styles.dart';
import 'package:video_editor/widgets/time_stamp_painer.dart';
import 'package:wav/wav_file.dart';

class AudioAnalysis extends StatefulWidget {
  const AudioAnalysis({super.key});

  @override
  State<AudioAnalysis> createState() => _AudioAnalysisState();
}

class _AudioAnalysisState extends State<AudioAnalysis> {
  /// [AudioPlayer] instance to play the audio from the file, in order to make the preview interactive.
  final AudioPlayer _player = AudioPlayer();

  /// [StreamSubscription] for the audio player's position. Canceled in dispose.
  late final StreamSubscription _playerPositionStream;

  /// [Duration] for the position of the audio player.
  Duration _playerPosition = const Duration();

  /// The length [Duration] of the audio file.
  Duration _audioLength = const Duration(milliseconds: 10000); //Placeholder duration

  /// [List] of the audio file's audio samples.
  final List<double> _samples = [];

  ///
  double _lengthInMillis = 0;

  /// [GlobalKey] assigned to the timestamp painer.
  final GlobalKey _paintKey = GlobalKey();

  /// The [Offset] of the latest mouse hit.
  Offset? _hitOffset;

  /// Starts to load the audio from the config video path.
  /// Calculates the length in milliseconds, chops the samples & adds them to the [List]
  Future<void> loadAudio() async {
    final Wav wav = await Wav.readFile(config.videoProject.config.audioPath);

    /// Total length / spp = length in seconds
    _lengthInMillis = ((wav.toMono().length / wav.samplesPerSecond) * 1000);

    final List<double> samplesData = reduceSamples(wav.toMono(), wav.samplesPerSecond);

    setState(() {
      _samples.clear();
      _samples.addAll(samplesData);
    });

    // Set the max duration for the waveform
    _audioLength = Duration(milliseconds: _lengthInMillis.round());

    // Listen for position changes, so that the state can change, whenever the position passes a beat.
    _playerPositionStream = _player.onPositionChanged.listen((event) {
      setState(() {
        // Enables the waveform to display the playback.
        _playerPosition = event;
        // TODO: toggle beat if detected (was a timestamp passed?)
        // Display beat with a certain time.
      });
    });

    // Start the playback
    _player.play(DeviceFileSource(config.config.audioPath));
  }

  ///
  Future<void> _executeTimeStamps() async {
    final JList<JDouble> doubles = AudioAnalyser.analyseStamps(
        JString.fromString(config.config.audioPath),
        config.config.peakThreshold,
        config.config.msThreshold);

    setState(() {
      config.config.beatStamps.clear();
      for (var element in doubles) {
        config.config.beatStamps.add(element.doubleValue(releaseOriginal: true));
      }
    });
  }

  void _addTimeStampForRemoval(final List<double> timeStamp) {
    for (final double element in timeStamp) {
      config.config.beatStamps.remove(element);
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
  void dispose() {
    super.dispose();
    _playerPositionStream.cancel();
    _player.dispose();

    // update all video clips...
    config.updateClipTimes();
  }

  void _exportBeatTimes() {
    final Future<String?> result =
        FilePicker.platform.saveFile(dialogTitle: "Save file", allowedExtensions: ['csv']);
    result.then((value) => exportAsCSV(value));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(path.basename(config.config.audioPath)),
        actions: [
          TextButton(
            onPressed: _exportBeatTimes,
            child: const Text('Export as CSV'),
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(25)),
          Text('Total cuts: ${config.config.beatStamps.length}'),
          const Padding(padding: EdgeInsets.all(25)),
          FlexibleSlider(
            onValueChanged: (p0) => config.config.peakThreshold = p0,
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
            onValueChanged: (p0) => config.config.msThreshold = p0,
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
          Expanded(
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
                      samples: _samples,
                      height: size.height * 0.5,
                      width: size.width * 0.95,
                      elapsedDuration: _playerPosition,
                      maxDuration: _audioLength,
                      activeColor: Colors.greenAccent,
                    ),
                  ),
                  CustomPaint(
                    key: _paintKey,
                    size: Size(
                      size.width * 0.95,
                      size.height * 0.5,
                    ),
                    foregroundPainter: TimeStampPainter(
                      timeStamps: config.config.beatStamps,
                      audioLength: _lengthInMillis,
                      hitOffset: _hitOffset,
                      hitTimeStamp: _addTimeStampForRemoval,
                      newTimeStamp: (t) => WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          config.config.beatStamps.add(t);
                          // Sort timestamps.
                          config.config.beatStamps.sort();
                        });
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //TODO: Play / pause in a single button..
                PlayerWidget(player: _player),
                TextButton(
                  onPressed: () => _executeTimeStamps(),
                  style: textButtonStyle(context),
                  child: const Text('Run analysis'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
