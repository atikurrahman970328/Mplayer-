import 'package:flutter/material.dart';

class KidsLockOverlay extends StatefulWidget {
  final VoidCallback onUnlock;

  const KidsLockOverlay({super.key, required this.onUnlock});

  @override
  State<KidsLockOverlay> createState() => _KidsLockOverlayState();
}

class _KidsLockOverlayState extends State<KidsLockOverlay> {
  int _tapCount = 0;

  void _handleTap() {
    setState(() => _tapCount++);
    if (_tapCount >= 3) {
      widget.onUnlock();
    } else {
      // ৩ সেকেন্ড পর কাউন্ট রিসেট হবে
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _tapCount = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(
        children: [
          // সমস্ত স্ক্রিন লকড
          Container(color: Colors.transparent),
          Positioned(
            top: 30,
            right: 30,
            child: AnimatedOpacity(
              opacity: _tapCount > 0 ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amberAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _tapCount == 0
                          ? "স্ক্রিন লক করা (লক খুলতে ৩ বার ট্যাপ করুন)"
                          : "লক খুলতে আর ${3 - _tapCount} বার ট্যাপ করুন",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}