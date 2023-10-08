import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class FileDrop extends StatefulWidget {
  final String fileType;
  final Function(XFile file) fileDropped;

  const FileDrop({Key? key, required this.fileDropped, required this.fileType}) : super(key: key);

  @override
  State<FileDrop> createState() => _FileDropState();
}

class _FileDropState extends State<FileDrop> {
  XFile? _droppedFile;

  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: DropTarget(
        onDragDone: (detail) {
          setState(() {
            //Validate the filetype (TODO), check the codec somehow...
            final XFile file = detail.files[0];

            _droppedFile = file;
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
          color: _dragging ? colorScheme.primary.withOpacity(0.4) : colorScheme.primaryContainer,
          child: _droppedFile == null
              ? Center(child: Text("Drop ${widget.fileType} here"))
              : Center(child: Text(_droppedFile!.name)),
        ),
      ),
    );
  }
}
