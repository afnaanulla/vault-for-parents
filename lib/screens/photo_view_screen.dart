import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewScreen extends StatefulWidget {
  final String imagePath;
  final String title;

  const PhotoViewScreen({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  final TransformationController _transformationController =
      TransformationController();
  int _quarterTurns = 0;

  void _zoomIn() {
    final Matrix4 current = _transformationController.value;
    _transformationController.value = current.clone()..scaleByDouble(1.3, 1.3, 1.0, 1.0);
  }

  void _zoomOut() {
    final Matrix4 current = _transformationController.value;
    _transformationController.value = current.clone()..scaleByDouble(0.77, 0.77, 1.0, 1.0);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);
    final fileExists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded),
            tooltip: 'Rotate',
            onPressed: _rotate,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Zoom',
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Image Canvas
          Center(
            child: !fileExists
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'Document photo not found on device',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  )
                : InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 6.0,
                    boundaryMargin: const EdgeInsets.all(40),
                    child: RotatedBox(
                      quarterTurns: _quarterTurns,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // Elderly-friendly on-screen Zoom Controls at bottom
          if (fileExists)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 28),
                        tooltip: 'Zoom Out',
                        onPressed: _zoomOut,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 28),
                        tooltip: 'Zoom In',
                        onPressed: _zoomIn,
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
