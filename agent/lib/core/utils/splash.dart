import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context) splashBuilder;
  final List<Future<dynamic>> initItems;
  final Duration minimumDuration;

  const SplashScreen({
    super.key,
    required this.child,
    required this.splashBuilder,
    this.initItems = const [],
    this.minimumDuration = const Duration(seconds: 1),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final startTime = DateTime.now();

    await Future.wait(widget.initItems);

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < widget.minimumDuration) {
      await Future.delayed(widget.minimumDuration - elapsed);
    }

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return widget.child;
    }
    return widget.splashBuilder(context);
  }
}
