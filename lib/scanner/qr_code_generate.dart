import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';


class GeneratorQrPage extends StatefulWidget {
  const GeneratorQrPage({super.key});

  @override
  State<GeneratorQrPage> createState() => _GeneratorQrPageState();
}

class _GeneratorQrPageState extends State<GeneratorQrPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _globalKey = GlobalKey();
  String _data = "";

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Generator"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_data.isNotEmpty)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _urlController.text.isEmpty ? 0 : 1,
                        child: RepaintBoundary(
                          key: _globalKey,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.white,
                            width: 300,
                            height: 300,
                            child: QrCodeGenerate(
                              data: _data,
                              qrSize: 300,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Put your link here',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Name your QR code (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _data = _urlController.text;
                          });
                        }
                      },
                      child: const Text("Generate QR Code"),
                    ),
                    const SizedBox(height: 8),
                    if (_data.isNotEmpty)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveLocalImage,
                            icon: const Icon(Icons.download),
                            label: const Text("Download QR Code"),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _shareQrCode,
                            icon: const Icon(Icons.share),
                            label: const Text("Share QR Code"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareQrCode() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await (image.toByteData(format: ui.ImageByteFormat.png));

      if (byteData != null) {
        final directory =
            await getTemporaryDirectory(); // Get the temp directory
        final file = await File('${directory.path}/qr_code.png').create();
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Sharing the XFile using shareXFiles
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _titleController.text,
        );
      }
    } catch (e) {
      _showToast("Error sharing QR code.", isError: true);
    }
  }

  Future<void> _saveLocalImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await (image.toByteData(format: ui.ImageByteFormat.png));
      if (byteData != null) {
        final result = await ImageGallerySaver.saveImage(
          byteData.buffer.asUint8List(),
          quality: 100,
        );
        if (result["isSuccess"] == true) {
          _showToast("QR Code saved successfully!");
        } else {
          _showToast("Failed to save QR Code.", isError: true);
        }
      }
    } catch (e) {
      _showToast("Error saving image.", isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

class QrCodeGenerate extends StatelessWidget {
  final String data;
  final double? qrSize;

  const QrCodeGenerate({required this.data, super.key, this.qrSize});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data.trim(),
      version: QrVersions.auto,
      size: qrSize ?? 70,
    );
  }
}
