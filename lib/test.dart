import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? _imageData;
  GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  GlobalKey _imageKey = GlobalKey();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageData = File(pickedFile.path).readAsBytesSync();
      });
    }
  }

  Future<void> _saveSignature() async {
    if (_imageData == null) return;

    RenderRepaintBoundary? boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      _saveImage(pngBytes);
    }
  }

  Future<void> _saveImage(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/signed_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);

      await ImageGallerySaver.saveImage(bytes, quality: 60, name: "image_name");
      // 파일 저장 후 필요한 처리를 수행합니다.
      print("Image saved to $imagePath");
    } catch (e) {
      print("Error saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Signature on Image App'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: RepaintBoundary(
                key: _imageKey,
                child: Stack(
                  children: [
                    _imageData == null
                        ? Center(child: Text('No image selected.'))
                        : Image.memory(_imageData!),
                    SfSignaturePad(
                      key: _signatureKey,
                      backgroundColor: Colors.transparent,
                      strokeColor: Colors.black,
                      minimumStrokeWidth: 1.0,
                      maximumStrokeWidth: 4.0,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
                ElevatedButton(
                  onPressed: _saveSignature,
                  child: Text('Save Signature'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
