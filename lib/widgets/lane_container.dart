import 'package:flutter/material.dart';
import 'package:video_editor/utils/extensions/build_context_extension.dart';

class TimeLineLane extends StatelessWidget {
  const TimeLineLane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.theme.hoverColor,
    );
  }
}
