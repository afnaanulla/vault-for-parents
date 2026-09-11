import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String title;
  final int initialIndex;

  const PhotoViewScreen({
    super.key,
    required this.imagePaths,
    required this.title,
    this.initialIndex = 0,
  });

  /// Convenience constructor for backwards compatibility with a single image path
  factory PhotoViewScreen.single({
    Key? key,
    required String imagePath,
    required String title,
  }) {
    return PhotoViewScreen(
      key: key,
      imagePaths: [imagePath],
      title: title,
      initialIndex: 0,
    );
  }

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _controllers = {};
  final Map<int, int> _rotations = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.imagePaths.isEmpty ? 0 : widget.imagePaths.length - 1,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  TransformationController _getController(int index) {
    return _controllers.putIfAbsent(index, () => TransformationController());
  }

  int _getRotation(int index) {
    return _rotations[index] ?? 0;
  }

  void _zoomIn() {
    final controller = _getController(_currentIndex);
    final Matrix4 current = controller.value;
    controller.value = current.clone()..scaleByDouble(1.3, 1.3, 1.0, 1.0);
  }

  void _zoomOut() {
    final controller = _getController(_currentIndex);
    final Matrix4 current = controller.value;
    controller.value = current.clone()..scaleByDouble(0.77, 0.77, 1.0, 1.0);
  }

  void _resetZoom() {
    _getController(_currentIndex).value = Matrix4.identity();
  }

  void _rotate() {
    setState(() {
      _rotations[_currentIndex] = ((_rotations[_currentIndex] ?? 0) + 1) % 4;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.imagePaths.length;
    final titleText = totalPages > 1
        ? '${widget.title} (${_currentIndex + 1} of $totalPages)'
        : widget.title;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          titleText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
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
          // Swipeable Photo Pages
          PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final path = widget.imagePaths[index];
              final file = File(path);
              final fileExists = file.existsSync();

              if (!fileExists) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'Document photo not found on device',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: InteractiveViewer(
                  transformationController: _getController(index),
                  minScale: 0.5,
                  maxScale: 8.0,
                  boundaryMargin: const EdgeInsets.all(40),
                  child: RotatedBox(
                    quarterTurns: _getRotation(index),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Page Dots Indicator (if more than 1 page)
          if (totalPages > 1)
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalPages, (i) {
                      final isActive = i == _currentIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          // Bottom Controls: Page Navigation & Zoom Buttons
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous page button (if multi-page)
                if (totalPages > 1)
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _currentIndex > 0
                          ? Colors.black.withValues(alpha: 0.75)
                          : Colors.black26,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: _currentIndex > 0
                        ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  )
                else
                  const SizedBox(width: 48),

                // Center Zoom In / Zoom Out Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 26),
                        tooltip: 'Zoom Out',
                        onPressed: _zoomOut,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 22,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 26),
                        tooltip: 'Zoom In',
                        onPressed: _zoomIn,
                      ),
                    ],
                  ),
                ),

                // Next page button (if multi-page)
                if (totalPages > 1)
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: _currentIndex < totalPages - 1
                          ? Colors.black.withValues(alpha: 0.75)
                          : Colors.black26,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                    onPressed: _currentIndex < totalPages - 1
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
