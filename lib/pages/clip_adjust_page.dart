import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_editor/utils/config.dart';
import 'package:video_editor/utils/model/video_clip.dart';

class ClipAdjust extends StatefulWidget {
  final VideoClip clip;

  const ClipAdjust({super.key, required this.clip});

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

  late final StreamSubscription<Duration> _playbackSubscription;

  late final TextEditingController _startController;
  late final TextEditingController _lengthController;

  Future<void> _initPlayer() async {
    await _player.open(Media(config.videoPath));
    await _player.seek(widget.clip.timeStamp.start);

    /// This is super fucking low tech
    bool seeking = false;
    _playbackSubscription = _player.stream.position.listen((event) async {
      if (event > widget.clip.timeStamp.start + widget.clip.clipLength && !seeking && _player.state.playing) {
        seeking = true;
        await _player.seek(widget.clip.timeStamp.start);
        seeking = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _startController =
        TextEditingController(text: widget.clip.timeStamp.start.inMilliseconds.toString());
    _lengthController =
        TextEditingController(text: widget.clip.clipLength.inMilliseconds.toString());
    _initPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    _playbackSubscription.cancel();
    _startController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    final Size size = MediaQuery.of(context).size;

    return Expanded(
      flex: 2,
      child: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
          keyboardShortcuts: {
            const SingleActivator(LogicalKeyboardKey.mediaPlay): () => _player.play(),
            const SingleActivator(LogicalKeyboardKey.mediaPause): () => _player.pause(),
            const SingleActivator(LogicalKeyboardKey.space): () => _player.playOrPause(),
            const SingleActivator(LogicalKeyboardKey.keyJ): () {
              final rate = _player.state.position - const Duration(seconds: 10);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.keyI): () {
              final rate = _player.state.position + const Duration(seconds: 10);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
              final rate = _player.state.position - const Duration(seconds: 2);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              final rate = _player.state.position + const Duration(seconds: 2);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.arrowUp): () {
              final rate = _player.state.position + const Duration(seconds: 60);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.arrowDown): () {
              final rate = _player.state.position - const Duration(seconds: 60);
              _player.seek(rate);
            },
            const SingleActivator(LogicalKeyboardKey.keyF): () => toggleFullscreen(context),
            const SingleActivator(LogicalKeyboardKey.escape): () => exitFullscreen(context),
            const SingleActivator(LogicalKeyboardKey.keyX): () {
              final Duration pos = _player.state.position;

              setState(() {
                widget.clip.timeStamp.start = pos;
                _startController.text = pos.inMilliseconds.toString();
              });
            }
          },
        ),
        fullscreen: const MaterialDesktopVideoControlsThemeData(),
        child: SizedBox(
          width: size.width,
          height: (size.width) * 9.0 / 16.0,
          child: Video(
            controller: _controller,
            wakelock: true,
          ),
        ),
      ),
    );
  }

  /// TODO: more user friendly version.
  /// for now, just two text-fields xd...
  /// one for the length, the other one for the start
  Widget _buildTrimmer() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: TextFormField(
                controller: _startController,
                decoration: const InputDecoration(labelText: 'Start time (ms)'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (value) =>
                    widget.clip.timeStamp.start = Duration(milliseconds: int.parse(value)),
              ),
            ),
            const Padding(padding: EdgeInsets.all(15)),
            Flexible(
              child: TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(labelText: 'Clip length (ms)'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (value) =>
                    widget.clip.clipLength = Duration(milliseconds: int.parse(value)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text('Easy Edits'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [_buildVideoPlayer(), _buildTrimmer()],
      ),
    );
  }
}
