import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'scan_preview_screen.dart';
import '../utils/image_cropper_helper.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  _ScanCameraScreenState createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializationFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initCamera();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller?.dispose();
      _controller = null;
    }
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy camera.')),
          );
        }
        return;
      }

      await _controller?.dispose();

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {});

    } catch (e) {
      print("Lỗi khởi tạo camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể khởi động camera: $e')),
        );
      }
    }
  }

  Future<void> _takePictureAndNavigate() async {
    if (_isTakingPicture) return;
    _isTakingPicture = true;

    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      _isTakingPicture = false;
      return;
    }

    try {
      final XFile image = await cameraController.takePicture();
      await Future.delayed(Duration(milliseconds: 500));
      // tắt camera
      await _controller?.dispose();
      _controller = null;
      _initializationFuture = null;

      if (mounted) setState(() {});

      final croppedFile = await cropToReceipt(image.path);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(croppedFile.path),
        ),
      );

      if (mounted) {
        setState(() {
          _initializationFuture = _initCamera();
        });
      }

    } catch (e) {
      print("Lỗi khi chụp ảnh: $e");
    } finally {
      _isTakingPicture = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Scan Hóa Đơn",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (_controller != null && _controller!.value.isInitialized) {
            final scale = 1 / (_controller!.value.aspectRatio * size.aspectRatio);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Center(child: CameraPreview(_controller!)),
                ),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(1.0),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: size.height * 0.75,
                          width: size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Khung viền xanh (Border)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: size.height * 0.75,
                    width: size.width * 0.9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 48),
                      onPressed: (_controller == null || !_controller!.value.isInitialized)
                          ? null
                          : _takePictureAndNavigate,
                    ),
                  ),
                ),

              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.white)),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
