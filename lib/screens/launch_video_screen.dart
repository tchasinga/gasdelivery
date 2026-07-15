import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the Gas Express launch video for ~4 seconds, then opens [next].
class LaunchVideoScreen extends StatefulWidget {
  const LaunchVideoScreen({super.key, required this.next});

  final Widget next;

  @override
  State<LaunchVideoScreen> createState() => _LaunchVideoScreenState();
}

class _LaunchVideoScreenState extends State<LaunchVideoScreen> {
  static const _assetPath = 'assets/gasexpresslauchscreenvideo.mp4';
  static const _splashDuration = Duration(seconds: 4);

  VideoPlayerController? _controller;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset(_assetPath);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.play();
      setState(() {});
    } catch (_) {
      // If the video fails, continue into the app after the timeout.
    }

    _timer = Timer(_splashDuration, _goToApp);
  }

  void _goToApp() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => widget.next,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: ready
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
