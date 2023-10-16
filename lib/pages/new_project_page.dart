import 'package:flutter/material.dart';
import 'package:video_editor/pages/audio_analysis.dart';
import 'package:video_editor/pages/error_page.dart';
import 'package:video_editor/pages/video_player.dart';
import 'package:video_editor/utils/config.dart' as config;
import 'package:video_editor/utils/file_util.dart' as file_util;
import 'package:video_editor/widgets/easy_edits_app_bar.dart';
import 'package:video_editor/widgets/file_drop.dart';


class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  void _navigateRoute(final BuildContext context, final String path) {
    final WidgetBuilder pageBuilder;

    if (file_util.isFileAudio(path)) {
      config.videoProject.config.audioPath = path;
      pageBuilder = (context) => const AudioAnalysis();
    } else if (file_util.isFileVideo(path)) {
      config.videoProject.config.videoPath = path;

      pageBuilder = (context) => const VideoPlayer();
    } else {
      pageBuilder = (context) => const ErrorPage(
          errorMessage: 'Wrong file-format. Please make sure that the supplied file compatible.',
          subtext: 'Compatible file formats: Video: HEVC, Audio: WAV.');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: pageBuilder),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: mainAppBar(context),
      body: Center(
        child: SizedBox(
          width: size.width - 50,
          height: size.height - 100,
          child: MediaFileDrop(
            fileType: 'Video or Audio',
            fileDropped: (file) => _navigateRoute(context, file.path),
          ),
        ),
      ),
    );
  }
}
