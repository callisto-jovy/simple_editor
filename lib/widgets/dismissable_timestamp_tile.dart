import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';

class TimeStampTile extends StatelessWidget {

  final DismissDirectionCallback onDismissed;
  final List<Widget> expansionWidgets;
  final int index;
  final Duration timeStamp;

  const TimeStampTile(
      {super.key,
      required this.index,
      required this.timeStamp,
      required this.onDismissed,
      required this.expansionWidgets});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.redAccent,
      ),
      onDismissed: onDismissed,
      child: ExpansionTile(
        leading: const Icon(Icons.timer),
        title: Text(
          'Segment ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(timeStamp.label()),
        children: expansionWidgets,
      ),
    );
  }
}
