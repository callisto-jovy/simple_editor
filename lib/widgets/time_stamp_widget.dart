import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/utils/cache_image_provider.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/transparent_image.dart';

class TimeStampCard extends StatelessWidget {
  final TimeStamp timeStamp;

  const TimeStampCard({super.key, required this.timeStamp});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: timeStamp.startFrame == null
              ? Image.memory(kTransparentImage)
              : Image(
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  image: CacheImageProvider(
                    '${timeStamp.start}',
                    Uint8List.view(timeStamp.startFrame!.buffer),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(timeStamp.start.label()),
        ),
      ],
    );
  }
}
