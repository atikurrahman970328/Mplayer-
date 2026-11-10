import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class GestureOverlay extends StatefulWidget {
  final Widget child;
  final Function(double delta) onVolumeDelta;
  final Function(double delta) onBrightnessDelta;
  final Function(Duration delta) onSeekDelta;
  final VoidCallback onSeekCommit;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final VoidCallback onDoubleTapCenter;
  final VoidCallback onSingleTap;

  const GestureOverlay({
    super.key,
    required this.child,
    required this.onVolumeDelta,
    required this.onBrightnessDelta,
    required this.onSeekDelta,
    required this.onSeekCommit,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onDoubleTapCenter,
    required this.onSingleTap,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
  Offset? _panStartPosition;
  bool _isHorizontalSeeking = false;
  double _horizontalAccumulator = 0.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSingleTap,
      onDoubleTapDown: (details) {
        final xPos = details.localPosition.dx;
        if (xPos < screenWidth * 0.35) {
          widget.onDoubleTapLeft(); // Rewind 10s
        } else if (xPos > screenWidth * 0.65) {
          widget.onDoubleTapRight(); // Forward 10s
        } else {
          widget.onDoubleTapCenter(); // Play / Pause
        }
      },
      onPanStart: (details) {
        _panStartPosition = details.localPosition;
        _isHorizontalSeeking = false;
        _horizontalAccumulator = 0.0;
      },
      onPanUpdate: (details) {
        if (_panStartPosition == null) return;

        final double totalDeltaX = details.localPosition.dx - _panStartPosition!.dx;
        final double totalDeltaY = details.localPosition.dy - _panStartPosition!.dy;

        // অনুভূমিকভাবে ড্র্যাগ করলে সিক (Forward / Rewind)
        if (totalDeltaX.abs() > totalDeltaY.abs() && totalDeltaX.abs() > 15) {
          _isHorizontalSeeking = true;
          _horizontalAccumulator += details.delta.dx;
          // প্রতি ড্র্যাগে আনুপাতিক সেকেন্ড হিসেব
          final seconds = (_horizontalAccumulator / 10).round();
          widget.onSeekDelta(Duration(seconds: seconds));
        }
        // উল্লম্ব ড্র্যাগ (বাম পাশে উজ্জ্বলতা, ডান পাশে সাউন্ড)
        else if (!_isHorizontalSeeking && totalDeltaY.abs() > 10) {
          final deltaChange = -details.delta.dy / 150.0;
          if (_panStartPosition!.dx < screenWidth / 2) {
            widget.onBrightnessDelta(deltaChange);
          } else {
            widget.onVolumeDelta(deltaChange);
          }
        }
      },
      onPanEnd: (_) {
        if (_isHorizontalSeeking) {
          widget.onSeekCommit();
        }
        _panStartPosition = null;
        _isHorizontalSeeking = false;
        _horizontalAccumulator = 0.0;
      },
      child: widget.child,
    );
  }
}

class GestureIndicatorHUD extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value; // 0.0 to 1.0 (for volume/brightness)

  const GestureIndicatorHUD({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}