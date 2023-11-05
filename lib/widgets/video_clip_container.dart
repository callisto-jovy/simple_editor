import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/pages/clip_adjust_page.dart';
import 'package:video_editor/utils/cache_image_provider.dart';
import 'package:video_editor/utils/model/video_clip.dart';

class VideoClipContainer extends StatelessWidget {
  final int index;
  final VideoClip videoClip;
  final double width;
  final Function() dismissedCallback;
  final Function(VideoClip) onStateChanged;

  const VideoClipContainer(
      {super.key,
      required this.index,
      required this.videoClip,
      required this.dismissedCallback,
      required this.width,
      required this.onStateChanged});

  void _handleClipTap(final BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ClipAdjust(videoClip: videoClip)));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Remove clip
    return UnconstrainedBox(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        height: 160,
        width: width,
        child: Dismissible(
          key: Key('$index'),
          onDismissed: (direction) => dismissedCallback.call(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                color: Colors.green,
                child: Text(
                  '$index',
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _handleClipTap(context),
                  child: Image(
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    image: CacheImageProvider(
                      '${videoClip.timeStamp.start}',
                      Uint8List.view(videoClip.timeStamp.startFrame!.buffer),
                    ),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                color: Colors.green,
                child: Text(
                  '${videoClip.timeStamp.start.label()} | ${videoClip.clipLength.inMilliseconds}ms',
                ),
              ),
              InkWell(
                onTap: () => onStateChanged.call(videoClip),
                child: Container(
                  alignment: Alignment.center,
                  color: videoClip.audioMuted ? Colors.white24 : Colors.white54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      videoClip.audioMuted
                          ? const Icon(Icons.volume_off)
                          : const Icon(Icons.volume_up),
                      const Text('Audio'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
