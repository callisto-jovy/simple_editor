import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:video_editor/utils/extensions/build_context_extension.dart';
import 'package:video_editor/utils/model/abstract_clip.dart';
import 'package:video_editor/utils/model/audio_clip.dart';

class TimeLine<T extends AbstractClip> extends StatefulWidget {
  /// [List] of type [T] holds the clips.
  final List<T> clips;

  /// [Function] which returns a [String] based on param [T] which is called when determining a label text for every clip.
  final String Function(T) labelText;

  const TimeLine({super.key, required this.clips, required this.labelText});

  @override
  State<TimeLine<T>> createState() => _TimeLineState<T>();
}

class _TimeLineState<T extends AbstractClip> extends State<TimeLine<T>> {
  /// [GlobalKey] assigned to the clip painter.
  final GlobalKey _videoTimeLineKey = GlobalKey();

  /// The [T] currently being dragged or null if no dragging is taking place.
  T? draggingClip;

  final ScrollController _timeLineScroll = ScrollController();

  /// TODO: use another hook.
  @override
  void didUpdateWidget(covariant TimeLine<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Make sure that all the clips are positioned accordingly.
    final RenderBox? renderBox = _videoTimeLineKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    for (final T clip in widget.clips) {
      clip.positionOffset = clip.constrainPosition(renderBox, clip.positionOffset);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _timeLineScroll.dispose();
  }

  void _handleDragStart(final PointerDownEvent event) {
    final RenderBox? renderBox = _videoTimeLineKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    // Find overlap.

    T? hitClip;

    for (final T clip in widget.clips) {
      if (clip.paintingBounds(context.mediaSize).contains(event.localPosition)) {
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

    // Offset within the bounds.
    final Offset positionOffset = draggingClip!.constrainPosition(renderBox, event.localPosition);

    /* Collision detection. */

    final Rect draggedRect = draggingClip!
        .paintingBoundsOffset(positionOffset, renderBox.size); // simulated new position.

    // Check whether the new rect overlaps with any OTHER clips.
    for (final T clip in widget.clips) {
      final Rect clipBounds = clip.paintingBounds(context.mediaSize);

      if (clip != draggingClip && clipBounds.overlaps(draggedRect)) {
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
      child: Container(
        color: context.theme.hoverColor,
        child: Row(
          children: widget.clips.map((e) {
            return Transform.translate(
              offset: e.positionOffset,
              child: PolygonWaveform(
                samples: (e as AudioClip).samples,
                width: e.width,
                height: e.height(context.mediaSize),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
