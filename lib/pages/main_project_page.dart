import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_editor/pages/audio_analysis_page.dart';
import 'package:video_editor/pages/clip_selection_page.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/utils/cache_image_provider.dart';
import 'package:video_editor/utils/config/config.dart' as config;
import 'package:video_editor/utils/backend/edit_util.dart';
import 'package:video_editor/utils/backend/frame_export_util.dart';
import 'package:video_editor/utils/model/audio_clip.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/backend/preview_util.dart' as preview;
import 'package:video_editor/widgets/snackbars.dart';
import 'package:video_editor/widgets/styles.dart';
import 'package:video_editor/widgets/time_stamp_widget.dart';
import 'package:video_editor/widgets/timeline_editor.dart';
import 'package:window_manager/window_manager.dart';

class MainProjectPage extends StatefulWidget {
  const MainProjectPage({super.key});

  @override
  State<MainProjectPage> createState() => _MainProjectPageState();
}

class _MainProjectPageState extends State<MainProjectPage> with WindowListener {
  /// [TextEditingController] which controls the video path
  final TextEditingController _videoPathController =
      TextEditingController(text: config.videoProject.config.videoPath);

  /// [TextEditingController] which controls the audio path
  final TextEditingController _audioPathController =
      TextEditingController(text: config.videoProject.config.audioPath);

  /// [TextEditingController] which controls the project name
  final TextEditingController _projectNameController =
      TextEditingController(text: config.videoProject.projectName);

  /// [StreamController] which is passed to the [TimeLineEditor] and triggers a refresh.
  final StreamController<List<VideoClip>> _videoClipController = StreamController();

  final StreamController<List<AudioClip>> _audioClipController = StreamController();

  final GlobalKey _dragTargetKey = GlobalKey();

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

  @override
  void dispose() {
    super.dispose();
    _videoPathController.dispose();
    _audioPathController.dispose();
    _projectNameController.dispose();
    _player.dispose();
    // Remove the window manager listener
    windowManager.removeListener(this);

    stopFrameExport();
  }

  @override
  void initState() {
    super.initState();
    // Add a new listener for the window closing.
    windowManager.addListener(this);

    // add the lastest preview path if not empty.
    if (config.config.previewPath.isNotEmpty) {
      _player.add(Media(config.config.previewPath));
    }

    windowManager.setPreventClose(true);
    _videoClipController.add(config.config.videoClips);

    setState(() {});

    startFrameExport();
  }


  @override
  void onWindowClose() {
    windowManager.isPreventClose().then((value) {
      if (value) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    // Save app state & then close.
                    config.saveApplicationState().then((value) {
                      Navigator.of(context).pop();
                      windowManager.destroy();
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _importProjectFile(final BuildContext context) {
    _loadFile(() {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Loaded config for ${config.videoProject.projectName}'),
      ));

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
          (Route<dynamic> route) => false);
    });
  }

  /// Pushes a new page
  void _navigateToPage(final BuildContext context, final StatefulWidget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void _generatePreview(final BuildContext buildContext) {
    ScaffoldMessenger.of(context).showSnackBar(successSnackbar('Generating preview...'));
    preview.generateEditPreview().then(_playPreview);
  }

  /// Play the edited preview
  void _playPreview(final String previewPath) {
    _player.stop();
    // set the path in the config, thereby delete the old preview
    config.handlePreview(previewPath).then((value) => _player.open(Media(previewPath)));
  }

  ///
  void _importFile(final Function(String) newPath) {
    FilePicker.platform.pickFiles(allowMultiple: false, dialogTitle: 'Pick file').then((value) {
      if (value != null) {
        newPath.call(value.files[0].path!);

        setState(() {});
      }
    });
  }

  void _saveProject(final BuildContext context) {
    config.saveApplicationState();
    ScaffoldMessenger.of(context).showSnackBar(successSnackbar('Successfully saved the project!'));
  }

  void _loadFile(Function() callback) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import save file',
      allowMultiple: false,
    );

    if (result != null) {
      await config.importFile(path: result.files[0].path);
      callback.call();
    }
  }

  void _timeStampDroppedOnTimeline(final TimeStamp timeStamp, final Offset offset) {
    final RenderBox? renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox?;
    // TODO: proper error
    if (renderBox == null) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackbar('Could not find render box.'));
      return;
    }

    // Convert the newly dropped timestamp to a clip
    final List<double> beatTimes = config.config.timeBetweenBeats();

    final int nextIndex = config.videoProject.config.videoClips.length;

    if (nextIndex >= beatTimes.length) {
      return;
    }

    final Duration beatLength = Duration(milliseconds: beatTimes[nextIndex].round());

    // Translate away from the center.
    final Offset translatedOffset = renderBox.globalToLocal(offset);

    final VideoClip videoClip =
        VideoClip(timeStamp, clipLength: beatLength, positionOffset: translatedOffset);
    // Constrain the position
    videoClip.positionOffset = videoClip.constrainPosition(renderBox, translatedOffset);

    final AudioClip audioClip = AudioClip(timeStamp: timeStamp.start, clipLength: beatLength, positionOffset: translatedOffset);
    audioClip.positionOffset = audioClip.constrainPosition(renderBox, translatedOffset);

    // Pass off to config to generate
    config.createVideoClip(videoClip);

    config.config.audioClips.add(audioClip);

    // pass the video projects, notify the projects
    _videoClipController.add(config.config.videoClips);

    _audioClipController.add(config.config.audioClips);
  }

  List<Widget> appBarTrailing(final BuildContext context) {
    return [
      TextButton(
        onPressed: () => _navigateToPage(context, const SettingsPage()),
        child: const Text('Settings'),
      ),
      TextButton(
        onPressed: () => _importProjectFile(context),
        child: const Text('Import'),
      ),
      TextButton(
        onPressed: () => edit(),
        child: const Text('Edit'),
      ),
      TextButton(
        onPressed: () => exportSegments(),
        child: const Text('Export Segments'),
      ),
      TextButton(
        onPressed: () => _saveProject(context),
        child: const Text('Save'),
      )
    ];
  }

  Widget _buildProjectName() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: EditableText(
        style: Theme.of(context).textTheme.headlineSmall!,
        controller: _projectNameController,
        focusNode: FocusNode(),
        cursorColor: Colors.blueGrey,
        backgroundCursorColor: Colors.white,
        onChanged: (value) => config.videoProject.projectName = value,
      ),
    );
  }

  Widget _buildAudioColumn(final BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0), // inner padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Audio',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            Text(config.videoProject.config.audioPath),
            const Padding(padding: EdgeInsets.all(10)),
            IconButton(
              onPressed: () => _importFile(config.setAudioPath),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
            const Padding(padding: EdgeInsets.all(5)),
            TextButton(
              onPressed: () => _navigateToPage(context, const AudioAnalysis()),
              style: textButtonStyle(context),
              child: const Text('Analyse Audio'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVideoColumn(final BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Video',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            Text(config.videoProject.config.videoPath),
            const Padding(padding: EdgeInsets.all(10)),
            IconButton(
              onPressed: () => _importFile((p0) => config.videoProject.config.videoPath = p0),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
            const Padding(padding: EdgeInsets.all(5)),
            TextButton(
              onPressed: () => _navigateToPage(context, const VideoPlayer()),
              style: textButtonStyle(context),
              child: const Text('Select Clips'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipsGrid(final BuildContext context) {
    return GridView.builder(
      itemCount: config.videoProject.config.timeStamps.length,
      itemBuilder: (context, index) {
        final TimeStamp timeStamp = config.videoProject.config.timeStamps[index];

        return LongPressDraggable(
          data: timeStamp,
          feedback: Image(
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            image: CacheImageProvider(
              '${timeStamp.start}',
              Uint8List.view(timeStamp.startFrame!.buffer),
            ),
          ),
          child: TimeStampCard(timeStamp: timeStamp),
        );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildClipsColumn(final BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                'Clips',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Padding(padding: EdgeInsets.all(10)),
              Expanded(child: _buildClipsGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// [Column] with the audio column, the video column and the video clips
  Widget _buildAudioAndClipsColumn(final BuildContext context) {
    return Column(
      children: [
        _buildAudioColumn(context),
        _buildVideoColumn(context),
        _buildClipsColumn(context),
      ],
    );
  }

  Widget _buildEditColumn(final BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        MaterialDesktopVideoControlsTheme(
          normal: MaterialDesktopVideoControlsThemeData(topButtonBar: [
            IconButton(
              tooltip: 'Preview edit.',
              onPressed: () => _generatePreview(context),
              icon: const Icon(Icons.preview),
            ),
          ]),
          fullscreen: const MaterialDesktopVideoControlsThemeData(
            displaySeekBar: true,
            automaticallyImplySkipNextButton: false,
            automaticallyImplySkipPreviousButton: false,
            //
          ),
          child: SizedBox(
            width: size.width,
            height: (size.height) * 9.0 / 16.0,
            child: Video(
              controller: _controller,
              wakelock: true,
            ),
          ),
        ),
        Flexible(
          child: DragTarget<TimeStamp>(
            key: _dragTargetKey,
            builder: (context, candidateData, rejectedData) {
              return TimeLineEditor(
                videoClipController: _videoClipController,
                audioClipController: _audioClipController,
                onReorder: (p0) => null,
              );
            },
            onAcceptWithDetails: (details) {
              _timeStampDroppedOnTimeline(details.data, details.offset);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: _buildProjectName(),
        actions: appBarTrailing(context),
      ),
      body: Row(
        children: [
          SizedBox(
            width: size.width * 0.15,
            height: size.height,
            child: _buildAudioAndClipsColumn(context),
          ),
          Expanded(
            child: _buildEditColumn(context),
          ),
        ],
      ),
    );
  }
}
