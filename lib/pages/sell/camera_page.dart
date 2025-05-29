import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/main.dart';
import 'item_details_page.dart';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  bool isInitialized = false;
  String? _capturedImagePath;
  late List<CameraDescription> cameras;
  bool isCaptured = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController.initialize();

      print("Sensor orientation: ${cameras[0].sensorOrientation}");
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      print("Camera initialization error: $e");
      Utils.showSnackBar(context, 'Error: $e');
    }
  }

  Widget _buildCameraPreview() {
    if (!_cameraController.value.isInitialized || _cameraController.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Positioned.fill(
      child: RotatedBox(
        quarterTurns: (cameras[0].sensorOrientation / 90).round(),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController.value.previewSize!.width,
            height: _cameraController.value.previewSize!.height,
            child: CameraPreview(_cameraController),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final originalImage = File(pickedFile.path);
        final bytes = await originalImage.readAsBytes();
        img.Image? decodedImage = img.decodeImage(bytes);

        if (decodedImage == null) return;

        // Step 1: Resize the image to a smaller dimension (keeping aspect ratio)
        final targetWidth = 1000; // Intermediate size for better quality
        final resizedImage = img.copyResize(
          decodedImage,
          width: targetWidth,
          height: (decodedImage.height * (targetWidth / decodedImage.width)).round(),
        );

        // Step 2: Crop the center 700x700
        final cropSize = 700;
        final offsetX = (resizedImage.width - cropSize) ~/ 2;
        final offsetY = (resizedImage.height - cropSize) ~/ 2;

        final croppedImage = img.copyCrop(
          resizedImage,
          x: offsetX,
          y: offsetY,
          width: cropSize,
          height: cropSize,
        );

        // Step 3: Save the final image
        final newPath = pickedFile.path.replaceFirst(RegExp(r'\.\w+$'), '_cropped.jpg');
        await File(newPath).writeAsBytes(img.encodeJpg(croppedImage, quality: 85));

        setState(() {
          _capturedImagePath = newPath;
          isCaptured = true;
          Utils.resetStatusBar();
        });
      } catch (e) {
        print("Error processing image: $e");
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final image = await _cameraController.takePicture();
      final originalImage = File(image.path);

      final decodedImage = img.decodeImage(originalImage.readAsBytesSync());
      if (decodedImage == null) return;

      final width = decodedImage.width;
      final height = decodedImage.height;

      final cropSize = 700;
      final offsetX = (width - cropSize) ~/ 2;
      final offsetY = (height - cropSize) ~/ 2;

      final croppedImage = img.copyCrop(decodedImage, x: offsetX, y: offsetY, width: cropSize, height: cropSize);

      final croppedImagePath = image.path.replaceFirst('.jpg', '_cropped.jpg');
      File(croppedImagePath).writeAsBytesSync(img.encodeJpg(croppedImage, quality: 100));

      setState(() {
        _capturedImagePath = croppedImagePath;
        isCaptured = true;
      });
    } catch (e) {
      print("Error capturing or processing image: $e");
    }
  }

  AppBar? _buildAppBar() {
    return isCaptured
        ? AppBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            elevation: 0,
            leading: _buildBackButton(true),
            title: Text(
              'Post Ad',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: [_buildCheckButton()],
          )
        : null;
  }

  Widget _buildBackButton(bool isPictureTaken) {
    return Padding(
      padding: EdgeInsets.only(left: isPictureTaken ? 0 : 4, top: isPictureTaken ? 0 : 32),
      child: IconButton(
        icon: Icon(
          CupertinoIcons.arrow_left,
          color: isPictureTaken ? Theme.of(context).colorScheme.onPrimary : Colors.white,
          size: 30,
        ),
        onPressed: () {
          setState(() {
            if (isPictureTaken) {
              _capturedImagePath = null;
              isCaptured = false;
            } else {
              Navigator.pop(context);
            }
          });
        },
      ),
    );
  }

  Widget _buildCheckButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(Icons.check, color: Colors.blue, size: 35),
        onPressed: () {
          if (_capturedImagePath != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailsPage(imagePath: _capturedImagePath!),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCapturedImage() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.19,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.file(
                File(_capturedImagePath!),
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                setState(() {
                  _capturedImagePath = null;
                  isCaptured = false;
                });
              },
              child: Text(
                "Retake",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: OverlayPainter(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.photo, color: Colors.white, size: 35),
              onPressed: _pickImageFromGallery,
            ),
            IconButton(
              icon: Icon(CupertinoIcons.circle_fill, size: 100, color: Colors.white),
              onPressed: _captureImage,
            ),
            IconButton(
              icon: Icon(Icons.clear, color: Colors.transparent, size: 35),
              onPressed: () {},
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNote() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Make sure your pic isn’t blurry!',
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isCaptured,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (isCaptured) {
          setState(() {
            _capturedImagePath = null;
            isCaptured = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isCaptured ? Theme.of(context).colorScheme.secondary : Colors.transparent,
        appBar: _buildAppBar(),
        body: isInitialized
            ? Stack(
                children: [
                  if (_capturedImagePath == null) _buildCameraPreview(),
                  if (_capturedImagePath == null) _buildOverlay(),
                  if (_capturedImagePath == null) _buildActionButtons(),
                  if (_capturedImagePath == null) _buildBackButton(false),
                  if (_capturedImagePath != null) _buildCapturedImage(),
                  // if (_capturedImagePath != null) _buildRetakeButton(),
                  if (_capturedImagePath != null) _buildNote(),
                ],
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: MediaQuery.of(navigatorKey.currentContext!).size.width * 0.9,
            height: MediaQuery.of(navigatorKey.currentContext!).size.width * 0.9,
          ),
          Radius.circular(60)))
      ..close();

    final overlayPath = Path.combine(PathOperation.difference, outerPath, cutoutPath);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
