import 'package:flutter/material.dart';
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/model/video_clip.dart';
import 'package:video_editor/widgets/time_line_painter.dart';

class VideoTimeLine extends StatefulWidget {
  final List<VideoClip> videoClips;

  const VideoTimeLine({super.key, required this.videoClips});

  @override
  State<VideoTimeLine> createState() => _VideoTimeLineState();
}

class _VideoTimeLineState extends State<VideoTimeLine> {
  /// [GlobalKey] assigned to the clip painter.
  final GlobalKey _videoTimeLineKey = GlobalKey();

  VideoClip? draggingClip;

  void _handleDragStart(final PointerDownEvent event) {
    final RenderBox? renderBox = _videoTimeLineKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    // Find overlap.

    VideoClip? hitClip;

    for (final VideoClip clip in widget.videoClips) {
      if (clip.positionOffset != null &&
          clip.paintingBounds(context.mediaSize).contains(event.localPosition)) {
        hitClip = clip;
      }
    }

    if (hitClip == null) return;

    setState(() {
      draggingClip = hitClip;
    });
  }

  void _handleDragging(final PointerMoveEvent event) {
    // Abort if not dragging anything.
    if (draggingClip == null) {
      return;
    }

    final RenderBox? renderBox = _videoTimeLineKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final Rect draggingRect = draggingClip!.paintingBounds(renderBox.size);

    final Offset mouseOffset = event.localPosition;

    // Elements are translated at their center.
    // therefore: Offset the center.
    final double limitX =
        mouseOffset.dx.clamp(draggingRect.width / 2, renderBox.size.width - draggingRect.width / 2);
    final double limitY = mouseOffset.dy
        .clamp(draggingRect.height / 2, renderBox.size.height - draggingRect.height / 2);

    // Offset within the bounds.
    final Offset positionOffset = Offset(limitX, limitY);

    /* Collision detection. */

    final Rect draggedRect = draggingClip!
        .paintingBoundsOffset(positionOffset, renderBox.size); // simulated new position.

    // Check whether the new rect overlaps with any OTHER clips.
    for (final VideoClip clip in widget.videoClips) {
      final Rect clipBounds = clip.paintingBounds(context.mediaSize);

      if (clip != draggingClip && clip.positionOffset != null && clipBounds.overlaps(draggedRect)) {
        return; // Stop. Don't update the position.
      }
    }

    // update the position if all checks passed.
    setState(() {
      draggingClip!.positionOffset = positionOffset;
    });
  }

  void _handleDragStop(final PointerUpEvent event) {
    if (draggingClip == null) {
      return;
    }

    final RenderBox? renderBox = _videoTimeLineKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    setState(() {
      draggingClip = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleDragStart,
      onPointerMove: _handleDragging,
      onPointerUp: _handleDragStop,
      behavior: HitTestBehavior.translucent,
      child: CustomPaint(
          key: _videoTimeLineKey,
          size: Size.infinite,
          foregroundPainter:
              TimeLinePainter(videoClips: widget.videoClips, draggingClip: draggingClip),
          child: const Placeholder()),
    );
  }
}
