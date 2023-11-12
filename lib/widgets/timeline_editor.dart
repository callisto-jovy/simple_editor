import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:jni/jni.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart';
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:video_editor/utils/audio/background_audio.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/lane_container.dart';
import 'package:video_editor/widgets/time_stamp_painer.dart';
import 'package:video_editor/widgets/timeline.dart';
import 'package:video_editor/widgets/video_clip_container.dart';

import '../utils/config/config.dart';

const double milliPixelMultiplier = 0.3; // Ten milliseconds are equal to one pixel.

class _TimeLineEditorState extends State<TimeLineEditor> {
  /// [ScrollController] for the list vies scroll
  final ScrollController _timeLineScroll = ScrollController();

  late double laneWidth = width(audioLength);

  /// The height of one editing lane, always a 24th of the screen size.
  late double laneHeight = context.mediaSize.height / 24;

  @override
  void dispose() {
    super.dispose();
    _timeLineScroll.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  double width(final double milliseconds) => milliseconds * milliPixelMultiplier;

  /// Red [Container] to signify the audio.
  Widget _buildAudioContainer() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: laneWidth,
        height: laneHeight,
        child: PolygonWaveform(
          samples: samples,
          height: laneHeight,
          width: laneWidth,
          absolute: true,

        ),
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          shadowColor: Colors.black,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildVideoLane() {
    return StreamBuilder(
      stream: widget.videoClipController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          //TODO: Empty lane
          return Container();
        }
        final List<VideoClip> clips = snapshot.data!;

        return SizedBox(
          width: laneWidth,
          height: laneHeight * 3,
          child: Container(
            color: context.theme.hoverColor,
            child: ReorderableListView.builder(
              itemCount: clips.length,
              padding: const EdgeInsets.all(5),
              scrollDirection: Axis.horizontal,
              proxyDecorator: _proxyDecorator,
              itemBuilder: (context, index) {
                final VideoClip videoClip = clips[index];
                // Map the millisecond range to the screen size
                final double height = laneHeight * 2;
                final double width = videoClip.clipLength.inMilliseconds * milliPixelMultiplier;

                return VideoClipContainer(
                  key: Key('${videoClip.timeStamp}$index'),
                  index: index,
                  videoClip: videoClip,
                  width: width,
                  height: height,
                  thumbnailGenerator: _thumbnailGenerator,
                );
              },
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex--;
                }
                setState(() {
                  final VideoClip item = clips.removeAt(oldIndex);
                  clips.insert(newIndex, item);

                  //TODO: range check
                  // TODO: Fix this stupidity.
                  // update all the clips.
                  for (int i = 0; i < config.timeBetweenBeats().length; i++) {
                    if (i < config.videoClips.length) {
                      clips[i].clipLength =
                          Duration(milliseconds: config.timeBetweenBeats()[i].round());
                    }
                  }

                  // Inform the parent that the clips have been reordered, so the backend can be updates accordingly.
                  widget.onReorder.call(clips);
                });
              },
            ),
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
          mainAxisAlignment: MainAxisAlignment.start,
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

  Future<Uint8List> _thumbnailGenerator(int timeStamp) async {
    final Uint8List data = await Isolate.run(() {
      final JByteBuffer frameBuffer = FlutterWrapper.getFrame(timeStamp);

      final int remaining = frameBuffer.remaining;
      final Uint8List data = Uint8List(remaining);
      // TODO: Use a more efficient approach when
      // https://github.com/dart-lang/jnigen/issues/387 is fixed.

      for (var i = 0; i < remaining; ++i) {
        data[i] = frameBuffer.nextByte;
      }

      frameBuffer.release();
      return data;
    });

    return data;
  }
}

class TimeLineEditor extends StatefulWidget {
  final StreamController<List<VideoClip>> videoClipController;
  final StreamController<List<AudioClip>> audioClipController;
  final Function(List<VideoClip>) onReorder;

  const TimeLineEditor(
      {super.key,
      required this.videoClipController,
      required this.audioClipController,
      required this.onReorder});

  @override
  State<TimeLineEditor> createState() => _TimeLineEditorState();
}
