import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MediaFileDrop extends StatefulWidget {
  final String fileType;
  final Function(XFile file) fileDropped;

  const MediaFileDrop({Key? key, required this.fileDropped, required this.fileType})
      : super(key: key);

  @override
  State<MediaFileDrop> createState() => _MediaFileDropState();
}

class _MediaFileDropState extends State<MediaFileDrop> {
  bool _dragging = false;

  void _filePickerDialoge() {
    FilePicker.platform.pickFiles(allowMultiple: false, dialogTitle: 'Pick files.').then((value) {
      if (value != null) {
        widget.fileDropped.call(XFile(value.files[0].path!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        setState(() {
          final XFile file = detail.files[0];
          widget.fileDropped.call(file);
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        color: _dragging
            ? Theme.of(context).colorScheme.surfaceVariant
            : Colors.blueGrey.withOpacity(0.2),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.perm_media_sharp, size: 128),
                const Padding(padding: EdgeInsets.all(15)),
                Text(
                  "DROP ${widget.fileType.toUpperCase()} HERE OR CLICK TO IMPORT.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(10)),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    padding: const EdgeInsets.all(15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () => _filePickerDialoge(),
                  child: const Text('Browse...'),
                ),
                const Padding(padding: EdgeInsets.all(10)),
                Text(
                  "Compatible file formats: Video: anything that is HEVC encoded, Audio: WAV.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
