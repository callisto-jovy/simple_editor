import 'package:video_editor/utils/model/abstract_clip.dart';

class AudioClip extends AbstractClip {


  Duration timeStamp;

  AudioClip({required this.timeStamp, required super.clipLength, required super.positionOffset});
}
