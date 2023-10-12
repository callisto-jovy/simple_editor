import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';

import 'package:icons_plus/icons_plus.dart';

import '../utils/model/timestamp.dart';

class TimeStampTile extends StatelessWidget {

  final DismissDirectionCallback onDismissed;
  final List<Widget> expansionWidgets;
  final int index;
  final TimeStamp timeStamp;

  const TimeStampTile(
      {super.key,
      required this.index,
      required this.timeStamp,
      required this.onDismissed,
      required this.expansionWidgets});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: DismissDirection.down,
      background: Container(
        color: Colors.redAccent,
      ),
      onDismissed: onDismissed,
      child: ExpansionTile(
        leading: const Icon(FontAwesome.timeline),
        title: Text(
          'Segment ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(timeStamp.start.label()),
        children: expansionWidgets,
      ),
    );
  }

  /*
  TimeStampTile(
          key: UniqueKey(),
            onDismissed: (direction) {
              setState(() {
                timeStamps.removeAt(index);
              });
            },
            index: index,
            timeStamp: stamp,
            expansionWidgets: [
              TextButton(
                  onPressed: () => _player.seek(stamp.start),
                  child: const Text('Seek to position')),
              TextButton(
                  onPressed: () => introStart = stamp.start,
                  child: const Text('Mark as intro start')),
              TextButton(
                onPressed: () => introEnd = stamp.start,
                child: const Text('Mark as intro stop'),
              ),
            ])
   */


  /*

    SizedBox(
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.memory(
                        Uint8List.view(timeStamp.startFrame!.buffer),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(timeStamp.start.label(), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            );

   */

/*
Expanded(
                    child: Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.down,
                      background: Container(
                        color: Colors.redAccent,
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          timeStamps.removeAt(index);
                        });
                      },
                      child: Expanded(
                        child: Card(
                          elevation: 5,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.memory(
                                  Uint8List.view(stamp.startFrame!.buffer),
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.low,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(stamp.start.label()),
                              ),
                              TextButton(
                                  onPressed: () => _player.seek(stamp.start),
                                  child: const Text('Seek to position')),
                              TextButton(
                                  onPressed: () => introStart = stamp.start,
                                  child: const Text('Mark as intro start')),
                              TextButton(
                                onPressed: () => introEnd = stamp.start,
                                child: const Text('Mark as intro stop'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
 */
}
