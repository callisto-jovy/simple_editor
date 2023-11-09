import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_editor/utils/backend/easy_edits_backend.dart' as backend;
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/backend/frame_export_util.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/transparent_image.dart';

class ClipAdjust extends StatefulWidget {
  final VideoClip videoClip;

  const ClipAdjust({super.key, required this.videoClip});

  @override
  State<ClipAdjust> createState() => _ClipAdjustState();
}

class _ClipAdjustState extends State<ClipAdjust> {
  /// Create a [Player] to control playback.
  final Player _player = Player(
    configuration: const PlayerConfiguration(
      title: 'Easy Edits',
      bufferSize: 1024 * 1024 * 1024,
      libass: true,
    ),
  );

  /// Create a [VideoController] to handle video output from [Player].
  late final VideoController _controller = VideoController(_player);

  /// [ScrollController] which controls the thumbnails.
  final ScrollController _timeLineScroll = ScrollController();

  final double thumbnailHeight = 200;

  // One thumbnail for every 200ms.
  late final int numberOfThumbnails = (widget.videoClip.clipLength.inMilliseconds / 200).round();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _timeLineScroll.dispose();
    stopFrameExport();
  }

  Stream<List<(String, Uint8List)>> getFrames() async* {
    final List<(String, Uint8List)> idFrameList = [];

    // every 200ms, we want a frame.
    for (int i = 0; i < numberOfThumbnails; i++) {
      final int offset = widget.videoClip.timeStamp.start.inMicroseconds + (i * 10000000);

      final Uint8List data = await Isolate.run(() {
        final JByteBuffer frameBuffer = backend.FlutterWrapper.getFrame(offset);

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

      idFrameList.add(('${i}_$offset', data));
      yield idFrameList;
    }
  }

  Widget _buildVideoTimeline() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _timeLineScroll,
      child: SizedBox(
        width: thumbnailHeight * numberOfThumbnails,
        height: context.mediaSize.height / 4,
        child: StreamBuilder(
          stream: getFrames(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            final List<(String, Uint8List)?> imageBytes = snapshot.data!;

            return Row(
              mainAxisSize: MainAxisSize.max,
              children: List.generate(
                numberOfThumbnails,
                (index) => SizedBox(
                  height: thumbnailHeight,
                  width: thumbnailHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 0.2,
                        child: Image.memory(
                          imageBytes[0] == null ? kTransparentImage : imageBytes[0]!.$2,
                          fit: BoxFit.cover,
                        ),
                      ),
                      index < imageBytes.length
                          ? FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: MemoryImage(imageBytes[index]!.$2),
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('Easy Edits'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              width: context.mediaSize.width,
              height: (context.mediaSize.width) * 9.0 / 16.0,
              child: Video(
                controller: _controller,
                wakelock: true,
              ),
            ),
          ),
          _buildVideoTimeline(),
        ],
      ),
    );
  }
}
