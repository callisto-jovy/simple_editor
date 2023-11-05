import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/utils/audio_data.dart';
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/lane_container.dart';
import 'package:video_editor/widgets/timeline.dart';

const double milliPixelMultiplier = 0.08; // Ten milliseconds are equal to one pixel.

class _TimeLineEditorState extends State<TimeLineEditor> {
  /// [ScrollController] for the list vies scroll
  final ScrollController _timeLineScroll = ScrollController();

  late double laneWidth = width(audioLength);

  /// The height of one editing lane, always a 24th of the screen size.
  late double laneHeight = context.mediaSize.height / 24;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timeLineScroll.dispose();
    super.dispose();
  }

  double width(final double milliseconds) => milliseconds * milliPixelMultiplier;

  /// Red [Container] to signify the audio.
  Widget _buildAudioContainer() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          SizedBox(
            width: laneWidth,
            height: laneHeight,
            child: PolygonWaveform(
              samples: samples,
              height: laneHeight,
              width: laneWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLane() {
    return StreamBuilder(
      stream: widget.videoClipController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: laneHeight,
            width: laneWidth,
            child: const TimeLineLane(),
          );
        }
        return SizedBox(
          height: laneHeight,
          width: laneWidth,
          child: TimeLine<VideoClip>(
            clips: snapshot.data!,
            labelText: (p0) => '${p0.clipLength.inMilliseconds} ms',
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
            height: laneHeight * 3,
            width: laneWidth,
            child: const TimeLineLane(),
          );
        }

        return SizedBox(
          height: laneHeight * 3,
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
    return Scrollbar(
      controller: _timeLineScroll,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _timeLineScroll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoLane(),
            _buildAudioLane(),
            _buildAudioContainer(),
          ],
        ),
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
