import 'dart:typed_data';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/pages/clip_adjust_page.dart';
import 'package:video_editor/utils/cache_image_provider.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/transparent_image.dart';

class VideoClipContainer extends StatelessWidget {
  final int index;
  final VideoClip videoClip;
  final double width;
  final double height;

  final Future<Uint8List> Function(int) thumbnailGenerator;

  VideoClipContainer(
      {super.key,
      required this.index,
      required this.videoClip,
      required this.width,
      required this.height,
      required this.thumbnailGenerator});

  void _handleClipTap(final BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ClipAdjust(videoClip: videoClip)));
  }

  // One thumbnail for every 500ms.
  late final int numberOfThumbnails = (videoClip.clipLength.inMilliseconds / 500).round();

  Stream<List<(String, Uint8List)>> getThumbnails() async* {
    final List<(String, Uint8List)> idFrameList = [];

    for (int i = 0; i < numberOfThumbnails; i++) {
      final int offset = videoClip.timeStamp.start.inMicroseconds + (i * 10000000);
      final Uint8List data = await thumbnailGenerator.call(offset);

      idFrameList.add(('${i}_$offset', data));
      yield idFrameList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            ContextMenuRegion(
              contextMenu: LinkContextMenu(url: 'http://flutter.dev'),
              child: StreamBuilder<List<(String, Uint8List)?>>(
                  stream: getThumbnails(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Placeholder();
                    }

                    final List<(String, Uint8List)?> imageBytes = snapshot.data!;

                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        numberOfThumbnails,
                        (index) => SizedBox(
                          height: height,
                          width: width / numberOfThumbnails,
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
                                      image: CacheImageProvider(
                                        '${videoClip.timeStamp.start}',
                                        Uint8List.view(videoClip.timeStamp.startFrame!.buffer),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            ),
            Text(
              '${videoClip.timeStamp.start.label()} | ${videoClip.clipLength.inMilliseconds}ms',
            ),
          ],
        ),
      ),
    );
  }
}
