import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'scan_preview_screen.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  _ScanCameraScreenState createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();

    _controller = CameraController(
      cameras!.first,
      ResolutionPreset.high,
    );

    await _controller!.initialize();
    setState(() => _isReady = true);
  }

  Future<void> _takePicture() async {
    final image = await _controller!.takePicture();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPreviewScreen(image.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator())
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),

          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: IconButton(
              iconSize: 70,
              icon: Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _takePicture,
            ),
          )
        ],
      ),
    );
  }
}