import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:path/path.dart' as path;
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/extensions/double_extension.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/video_clip_container.dart';
import 'package:video_editor/widgets/video_timeline.dart';
import 'package:wav/wav.dart';

class _TimeLineEditorState extends State<TimeLineEditor> {
  /// [ScrollController] for the list vies scroll
  final ScrollController _timeLineScroll = ScrollController();

  double audioLength = 100000; // just so that there is no infinite width.

  /// Starts to load the audio from the config video path.
  /// Calculates the length in milliseconds, chops the samples & adds them to the [List]
  Future<void> _loadAudio() async {
    if (config.videoProject.config.audioPath.isEmpty) {
      return;
    }

    final Wav wav = await Wav.readFile(config.videoProject.config.audioPath);

    /// Total length / spp = length in seconds
    audioLength = ((wav.toMono().length / wav.samplesPerSecond) * 1000);
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
    return SingleChildScrollView(
      child: Container(
        height: 25,
        width: audioLength.remap(0, audioLength, 0, context.mediaSize.width),
        color: Colors.redAccent,
        child: Text(
          path.basenameWithoutExtension(config.videoProject.config.audioPath),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTimeline(final List<VideoClip> clips, final Size size) {
    return ReorderableListView.builder(
      itemCount: clips.length,
      padding: const EdgeInsets.all(15),
      scrollDirection: Axis.horizontal,
      scrollController: _timeLineScroll,
      itemBuilder: (context, index) {
        final VideoClip videoClip = clips[index];
        // Map the millisecond range to the screen size
        final double width = videoClip.clipLength.inMilliseconds
            .toDouble()
            .remap(0, audioLength, 240, size.width / 4);

        return VideoClipContainer(
          key: Key('$index'),
          index: index,
          videoClip: videoClip,
          dismissedCallback: () {
            setState(() {
              clips.remove(videoClip);
              config.config.videoClips.remove(videoClip);
            });
          },
          width: width,
          onStateChanged: (p0) {
            setState(() {
              videoClip.audioMuted = !videoClip.audioMuted;

              // update the backend
              widget.onStateChanged.call(videoClip);
            });
          },
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        setState(() {
          final VideoClip item = clips.removeAt(oldIndex);
          clips.insert(newIndex, item);

          //TODO: range check
          // TODO: Fix this stupidity.
          // update all the clips.
          config.videoProject.config.timeBetweenBeats().then((value) {
            for (int i = 0; i < clips.length; i++) {
              if (i < value.length) {
                clips[i].clipLength = Duration(milliseconds: value[i].round());
              }
            }

            // Inform the parent that the clips have been reordered, so the backend can be updates accordingly.
            widget.onReorder.call(clips);
          });
        });
      },
    );
  }

  Widget _buildTimeLineReal() {
    return Column(
      children: [
        Flexible(
          child: GridView(
            scrollDirection: Axis.horizontal,
            controller: _timeLineScroll,
            physics: const RangeMaintainingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, childAspectRatio: 0.36),
            children: List.generate(
              50,
              (index) => UnconstrainedBox(
                child: Container(
                  color: Colors.green,
                  width: 400,
                  height: 50,
                  child: Text('item: $index'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioLine() {
    return Container(
      color: Colors.blueAccent,
      width: context.mediaSize.width,
      alignment: Alignment.center,
      height: 120,
      child: Text(textAlign: TextAlign.center, 'Audio'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder(
          stream: widget.videoClipController.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Flexible(child: Container());
            }
            return Flexible(
              child: TimeLine<VideoClip>(
                clips: snapshot.data!,
                labelText: (p0) => p0.timeStamp.start.label(),
              ),
            );
          },
        ),
        _buildAudioLine(),
        _buildAudioContainer(),
      ],
    );
  }
}

class TimeLineEditor extends StatefulWidget {
  final StreamController<List<VideoClip>> videoClipController;

  final Function(List<VideoClip>) onReorder;
  final Function(VideoClip) onStateChanged;

  const TimeLineEditor(
      {super.key,
      required this.videoClipController,
      required this.onReorder,
      required this.onStateChanged});

  @override
  State<TimeLineEditor> createState() => _TimeLineEditorState();
}
