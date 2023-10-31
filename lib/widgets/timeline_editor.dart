import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/extensions/double_extension.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/lane_container.dart';
import 'package:video_editor/widgets/timeline.dart';
import 'package:wav/wav.dart';

const double kLaneHeight = 50;
const double secondToPixel = 0.1; // One second is equal to s * 0.1 * width


class _TimeLineEditorState extends State<TimeLineEditor> {
  /// [ScrollController] for the list vies scroll
  final ScrollController _timeLineScroll = ScrollController();

  double audioLength = 100000; // just so that there is no infinite width.

  late double laneWidth = context.mediaSize.width;

  /// Starts to load the audio from the config video path.
  /// Calculates the length in milliseconds, chops the samples & adds them to the [List]
  Future<void> _loadAudio() async {
    if (config.videoProject.config.audioPath.isEmpty) {
      return;
    }

    final Wav wav = await Wav.readFile(config.videoProject.config.audioPath);

    setState(() {
      /// Total length / spp = length in seconds
      audioLength = ((wav.toMono().length / wav.samplesPerSecond) * 1000);
      laneWidth = (audioLength / 1000) * secondToPixel * context.mediaSize.width;
    });
  }

  @override
  void initState() {
    _loadAudio();
    super.initState();
  }

  @override
  void dispose() {
    _timeLineScroll.dispose();
    super.dispose();
  }

  /// Red [Container] to signify the audio.
  Widget _buildAudioContainer() {
    return Container(
      height: 25,
      width: laneWidth,
      color: Colors.redAccent,
      child: Text(
        path.basenameWithoutExtension(config.videoProject.config.audioPath),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVideoLane() {
    return StreamBuilder(
      stream: widget.videoClipController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: kLaneHeight,
            width: laneWidth,
            child: const TimeLineLane(),
          );
        }
        return SizedBox(
          height: kLaneHeight,
          width: laneWidth,
          child: TimeLine<VideoClip>(
            clips: snapshot.data!,
            labelText: (p0) => p0.timeStamp.start.label(),
          ),
        );
      },
    );
  }

  Widget _buildAudioLane() {
    return StreamBuilder(
      stream: widget.audioClipController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: kLaneHeight * 3,
            width: laneWidth,
            child: const TimeLineLane(),
          );
        }
        return SizedBox(
          height: kLaneHeight * 3,
          width: laneWidth,
          child: TimeLine<AudioClip>(
            clips: snapshot.data!,
            labelText: (p0) => p0.timeStamp.label(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _timeLineScroll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVideoLane(),
          _buildAudioLane(),
          _buildAudioContainer(),
        ],
      ),
    );
  }
}

class TimeLineEditor extends StatefulWidget {
  final StreamController<List<VideoClip>> videoClipController;
  final StreamController<List<AudioClip>> audioClipController;

  const TimeLineEditor(
      {super.key, required this.videoClipController, required this.audioClipController});

  @override
  State<TimeLineEditor> createState() => _TimeLineEditorState();
}
