import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/widgets/cache_image_provider.dart';
import 'package:video_editor/widgets/custom_video_controls.dart' as custom_controls;

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({super.key});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

///
class _VideoPlayerState extends State<VideoPlayer> {
  /// Create a [Player] to control playback.
  final _player = Player(
    configuration: const PlayerConfiguration(
      title: 'Easy Edits',
      bufferSize: 1024 * 1024 * 1024,
      libass: true,
    ),
  );

  /// Create a [VideoController] to handle video output from [Player].
  late final _controller = VideoController(_player);

  final ScrollController _scrollController = ScrollController();
  final ScrollController _timeLineScroll = ScrollController();

  final List<TimeStamp> timeStamps = [];
  Duration? introStart, introEnd;

  Future<void> _loadTimeStamps() async {
    for (final TimeStamp stamp in config.videoProject.config.timeStamps) {
      if (stamp.startFrame == null) {
        await _player.seek(stamp.start);
        final Uint8List? frame = await _player.screenshot();

        timeStamps.add(await createTimeStamp(stamp.start, frame));
      } else {
        timeStamps.add(stamp);
      }
    }
    setState(() {
      _player.seek(const Duration(seconds: 0));
    });
  }

  @override
  void initState() {
    // Open the media in a new microtask
    _player.open(Media(config.videoProject.config.videoPath)).then((value) => _loadTimeStamps());

    super.initState();
  }

  @override
  void dispose() {
    config.videoProject.config.timeStamps.clear();
    config.videoProject.config.timeStamps.addAll(timeStamps);
    config.videoProject.config.introStart = introStart;
    config.videoProject.config.introEnd = introEnd;
    _player.dispose();
    _scrollController.dispose();
    _timeLineScroll.dispose();
    super.dispose();

  }

  Widget _buildVideo(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Expanded(
      flex: 2,
      child: custom_controls.CustomMaterialDesktopVideoControlsTheme(
        normal: custom_controls.CustomMaterialDesktopVideoControlsThemeData(
          seekBar: custom_controls.CustomMaterialDesktopSeekBar(
            timeStamps: timeStamps.map((e) => e.start).toList(), //TODO: better solution
            introStart: introStart,
            introEnd: introEnd,
          ),
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
              Future.microtask(() async {
                final Uint8List? frame = await _player.screenshot();

                createTimeStamp(pos, frame).then((value) {
                  setState(() {
                    timeStamps.add(value);
                  });
                });
              });
            }
          },
          buttonBarButtonSize: 24.0,
          buttonBarButtonColor: Colors.white,
          bottomButtonBar: [
            const MaterialDesktopSkipPreviousButton(),
            const MaterialDesktopPlayOrPauseButton(),
            const MaterialDesktopSkipNextButton(),
            const MaterialDesktopVolumeButton(),
            const MaterialDesktopPositionIndicator(),
            const Spacer(),
            const MaterialDesktopFullscreenButton(),
          ],
        ),
        fullscreen: const custom_controls.CustomMaterialDesktopVideoControlsThemeData(
          displaySeekBar: false,
          automaticallyImplySkipNextButton: false,
          automaticallyImplySkipPreviousButton: false,
        ),
        child: SizedBox(
          width: size.width,
          height: (size.width) * 9.0 / 16.0,
          child: Video(
            controller: _controller,
            wakelock: true,
            controls: (state) => custom_controls.CustomMaterialDesktopVideoControls(state),
          ),
        ),
      ),
    );
  }

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.blueGrey,
          shadowColor: Colors.black,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildTimeLine(final BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Expanded(
      child: SizedBox(
        width: size.width,
        child: Card(
          child: Scrollbar(
            controller: _timeLineScroll,
            child: ReorderableListView.builder(
              proxyDecorator: proxyDecorator,
              itemBuilder: (context, index) {
                final TimeStamp stamp = timeStamps[index];
                return Card(
                  key: Key('$stamp$index'),
                  elevation: 5,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image(
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.low,
                            image: CacheImageProvider(
                              '${stamp.start}',
                              Uint8List.view(stamp.startFrame!.buffer),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text('${stamp.start.label()} Segment ${index + 1}'),
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
                );
              },
              itemCount: timeStamps.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final TimeStamp item = timeStamps.removeAt(oldIndex);
                  timeStamps.insert(newIndex, item);
                });
              },
              scrollController: _timeLineScroll,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: const Text('Editing options'),
              ),
            ],
          ),
        ],
        centerTitle: true,
        title: const Text('Easy Edits'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [_buildVideo(context), _buildTimeLine(context)],
      ),
    );
  }
}
