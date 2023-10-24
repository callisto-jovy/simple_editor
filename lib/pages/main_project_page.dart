import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/settings_page.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/easy_edits_backend.dart';
import 'package:video_editor/utils/error_util.dart';
import 'package:video_editor/utils/model/timestamp.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/utils/preview_util.dart' as preview;
import 'package:video_editor/widgets/cache_image_provider.dart';
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
  final StreamController<List<VideoClip>> _clipController = StreamController();

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
  }

  @override
  void initState() {
    super.initState();
    // Add a new listener for the window closing.
    windowManager.addListener(this);

    // add the lastest preview path if not empty.
    if (config.videoProject.config.previewPath.isNotEmpty) {
      _player.add(Media(config.videoProject.config.previewPath));
    }

    windowManager.setPreventClose(true);
    setState(() {});
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
            });
      }
    });
  }

  /// Pushes the video player page
  void _navigateToVideo(final BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoPlayer(),
      ),
    );
  }

  /// Pushes the audio analysis page
  void _navigateToAudio(final BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AudioAnalysis(),
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
      config.importFile(path: result.files[0].path);
      callback.call();
    }
  }

  Future<void> _edit() async {
    await config.ensureOutExists();
    //TODO: Make sure that the state is fulfilled.
    final String json = config.toEditorConfig();
    // Run the export process in a new isolate
    await Isolate.run(() => FlutterWrapper.edit(JString.fromString(json))).then((value) {
      LocalNotification(
        title: 'Easy Edits',
        body: 'Done editing.',
      ).show();
    }).onError((error, stackTrace) {
      dumpErrorLog(error, stackTrace);

      LocalNotification(
        title: 'Easy Edits',
        body:
            'An error occurred. The error has been dumped in a logfile. If you decide to open a report, attach this log.',
      ).show();
    });
  }

  Future<void> _exportSegments() async {
    await config.ensureOutExists();
    //TODO: Make sure that the state is fulfilled.
    final String json = config.toEditorConfig();
    // Run the export process in a new isolate
    await Isolate.run(() => FlutterWrapper.exportSegments(JString.fromString(json))).then((value) {
      LocalNotification(
        title: 'Easy Edits',
        body: 'Done exporting the segments.',
      ).show();
    });
  }

  void _timeStampDroppedOnTimeline(final TimeStamp timeStamp) {
    // Convert the newly dropped timestamp to a clip
    final List<double> beatTimes = config.videoProject.config.timeBetweenBeats();

    final int nextIndex = config.videoProject.config.videoClips.length;

    if (nextIndex >= beatTimes.length) {
      return;
    }
    final Duration beatLength = Duration(milliseconds: beatTimes[nextIndex].round());

    final VideoClip clip = VideoClip(timeStamp, beatLength);
    // Pass off to config to generate
    config.createVideoClip(clip);

    // pass the video projects, notify the projects
    _clipController.add(config.videoProject.config.videoClips);
  }

  List<Widget> appBarTrailing(final BuildContext context) {
    return [
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        },
        child: const Text('Settings'),
      ),
      TextButton(
        onPressed: () => _loadFile(() {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Loaded config for ${config.videoProject.projectName}'),
          ));

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainProjectPage(), maintainState: true),
              (Route<dynamic> route) => false);
        }),
        child: const Text('Import'),
      ),
      TextButton(
        onPressed: () => _edit(),
        child: const Text('Edit'),
      ),
      TextButton(
        onPressed: () => _exportSegments(),
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
              onPressed: () => _importFile((p0) => config.videoProject.config.audioPath = p0),
              icon: const Icon(Icons.file_open),
              style: iconButtonStyle(context),
            ),
            const Padding(padding: EdgeInsets.all(5)),
            TextButton(
              onPressed: () => _navigateToAudio(context),
              style: textButtonStyle(context),
              child: const Text('Edit'),
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
              onPressed: () => _navigateToVideo(context),
              style: textButtonStyle(context),
              child: const Text('Edit'),
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
            builder: (context, candidateData, rejectedData) {
              return TimeLineEditor(
                videoClipController: _clipController,
                onReorder: config.updateVideoClips,
                onStateChanged: config.updateVideoClip,
                // whenever the reordering is done, we generate a new edit preview.
              );
            },
            onAccept: (data) {
              _timeStampDroppedOnTimeline(data);
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
            width: size.width * 0.25,
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
