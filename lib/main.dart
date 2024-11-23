import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(ImageDividerApp());
}

class ImageDividerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divisor de Imágenes',
      home: ImageDividerScreen(),
    );
  }
}

class ImageDividerScreen extends StatefulWidget {
  @override
  _ImageDividerScreenState createState() => _ImageDividerScreenState();
}

class _ImageDividerScreenState extends State<ImageDividerScreen> {
  int gridSize = 9; // Default grid size
  File? selectedImage;

  Future<void> selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      processImage(File(pickedFile.path));
    }
  }

  Future<void> processImage(File imageFile) async {
    try {
      // Load the image
      final imageBytes = await imageFile.readAsBytes();
      final img.Image originalImage = img.decodeImage(imageBytes)!;

      // Determine grid size
      int rows = sqrt(gridSize).toInt();
      int cols = rows;
      int tileWidth = (originalImage.width / cols).floor();
      int tileHeight = (originalImage.height / rows).floor();

      // Prepare output directory
      final originalDir = imageFile.parent;
      final muralDir = Directory('${originalDir.path}/murales');
      if (!await muralDir.exists()) {
        await muralDir.create(recursive: true);
      }

      // Prepare PDF
      final pdf = pw.Document();
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          int left = col * tileWidth;
          int top = row * tileHeight;
          int right = min(left + tileWidth, originalImage.width);
          int bottom = min(top + tileHeight, originalImage.height);

          img.Image tile = img.copyCrop(
            originalImage,
            x: left,
            y: top,
            width: right - left,
            height: bottom - top,
          );
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(img.encodeJpg(tile)),
                  ),
                );
              },
            ),
          );
        }
      }

      // Save PDF
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath = '${muralDir.path}/partes_mural_$timestamp.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // Notify user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Imagen dividida en $gridSize partes. Guardada en: $pdfPath'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ocurrió un error: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Divisor de Imágenes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Selecciona el tipo de mural:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<int>(
                  value: 9,
                  groupValue: gridSize,
                  onChanged: (value) {
                    setState(() {
                      gridSize = value!;
                    });
                  },
                ),
                Text('3x3 (9 partes)'),
                SizedBox(width: 20),
                Radio<int>(
                  value: 16,
                  groupValue: gridSize,
                  onChanged: (value) {
                    setState(() {
                      gridSize = value!;
                    });
                  },
                ),
                Text('4x4 (16 partes)'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectImage,
              child: Text('Seleccionar Imagen'),
            ),
          ],
        ),
      ),
    );
  }
}
