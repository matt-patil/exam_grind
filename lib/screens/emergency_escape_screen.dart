import 'package:flutter/material.dart';
import 'dart:async';

class EmergencyEscapeScreen extends StatefulWidget {
  const EmergencyEscapeScreen({super.key});

  @override
  State<EmergencyEscapeScreen> createState() => _EmergencyEscapeScreenState();
}

class _EmergencyEscapeScreenState extends State<EmergencyEscapeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Emergency Escape Mode', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Remember, only use this if needed absolutely.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              const SizedBox(height: 80),
              GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[800],
                            color: Colors.redAccent,
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: _controller.isAnimating && _controller.status == AnimationStatus.forward
                                ? Colors.redAccent.withValues(alpha: 0.8)
                                : Colors.redAccent.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'Escape!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Hold for 10 seconds to dismiss alarm',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
