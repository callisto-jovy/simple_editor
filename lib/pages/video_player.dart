import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_editor/utils/config_util.dart' as config;
import 'package:video_editor/widgets/custom_video_controls.dart' as custom_controls;
import 'package:video_editor/widgets/dismissable_timestamp_tile.dart';

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
  ));

  /// Create a [VideoController] to handle video output from [Player].
  late final _controller = VideoController(_player);

  final ScrollController _scrollController = ScrollController();

  final List<Duration> timeStamps = [];
  Duration? introStart, introEnd;

  @override
  void initState() {
    // Open the media in a new microtask
    Future.microtask(() => _player.open(Media(config.videoPath)));

    timeStamps.clear();
    timeStamps.addAll(config.timeStamps);

    super.initState();
  }

  @override
  void dispose() {
    config.timeStamps.clear();
    config.timeStamps.addAll(timeStamps);
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildVideo(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return custom_controls.CustomMaterialDesktopVideoControlsTheme(
      normal: custom_controls.CustomMaterialDesktopVideoControlsThemeData(
        seekBar: custom_controls.CustomMaterialDesktopSeekBar(
          timeStamps: timeStamps,
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
          const SingleActivator(LogicalKeyboardKey.keyX): () => setState(() {
                timeStamps.add(_player.state.position);
              })
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
          MaterialDesktopCustomButton(
            onPressed: () => setState(() {
              timeStamps.add(_player.state.position);
            }),
            icon: const Icon(Icons.bookmark_add),
          ),
        ],
      ),
      fullscreen: const custom_controls.CustomMaterialDesktopVideoControlsThemeData(
        displaySeekBar: false,
        automaticallyImplySkipNextButton: false,
        automaticallyImplySkipPreviousButton: false,
      ),
      child: SizedBox(
        width: size.width,
        height: size.width * 9.0 / 16.0,
        child: Video(
          controller: _controller,
          wakelock: true,
          controls: (state) => custom_controls.CustomMaterialDesktopVideoControls(state),
        ),
      ),
    );
  }

  Widget _buildSliderColumn(final BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
            'TimeStamps',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(10),
            shrinkWrap: true,
            scrollController: _scrollController,
            itemCount: timeStamps.length,
            itemBuilder: (context, index) {
              final Duration stamp = timeStamps[index];
              return TimeStampTile(
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
                        onPressed: () => _player.seek(stamp),
                        child: const Text('Seek to position')),
                    TextButton(
                        onPressed: () => introStart = stamp,
                        child: const Text('Mark as intro start')),
                    TextButton(
                      onPressed: () => introEnd = stamp,
                      child: const Text('Mark as intro stop'),
                    ),
                  ]);
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Duration item = timeStamps.removeAt(oldIndex);
                timeStamps.insert(newIndex, item);
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SliderDrawer(
          slideDirection: SlideDirection.RIGHT_TO_LEFT,
          appBar: SliderAppBar(
            appBarColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text(''),
            appBarHeight: kToolbarHeight,
            appBarPadding: const EdgeInsets.all(10),
            trailing: const BackButton(),
          ),
          slider: _buildSliderColumn(context),
          child: _buildVideo(context)),
    );
  }
}
