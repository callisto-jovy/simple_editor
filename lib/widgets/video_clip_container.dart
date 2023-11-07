import 'dart:typed_data';

import 'package:flutter/gestures.dart';
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

  // TODO: Check the image cache before requesting the backend.
  // This will eliminate a lot of slowdown.
  Stream<List<(String, Uint8List)>> getThumbnails() async* {
    final List<(String, Uint8List)> idFrameList = [];

    for (int i = 0; i < numberOfThumbnails; i++) {
      final int offset = videoClip.timeStamp.start.inMicroseconds + (i * 10000000);

      final Uint8List data = await thumbnailGenerator.call(offset);

      idFrameList.add(('${i}_$offset', data));
      yield idFrameList;
    }
  }

  void _showCustomMenu(final BuildContext context, final PointerDownEvent event) {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay == null || event.buttons != kSecondaryButton) {
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        event.position.dx,
        event.position.dy,
        overlay.size.width - event.position.dx,
        overlay.size.height - event.position.dy,
      ),
      items: [
        PopupMenuItem(
          child: const Text('See clip'),
          onTap: () => _handleClipTap(context),
        ),
        PopupMenuItem(
          child: const Text("Remove clip"),
          onTap: () {}, //TODO: remove clip callback
        )
      ],
    );
  }

  ImageProvider<CacheImageProvider> _cachedImage(final (String, Uint8List) obj) {
    return CacheImageProvider(
      obj.$1,
      obj.$2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Listener(
              onPointerDown: (event) => _showCustomMenu(context, event),
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
                                child: imageBytes[0] == null
                                    ? Image.memory(kTransparentImage,
                                        fit: BoxFit.cover) // Transparent placeholder
                                    : Image(
                                        image: _cachedImage(imageBytes[0]!),
                                        fit: BoxFit.cover, // Last image as a placeholder
                                      ),
                              ),
                              index < imageBytes.length
                                  ? FadeInImage(
                                      placeholder: placeHolder,
                                      image: _cachedImage(imageBytes[index]!),
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
