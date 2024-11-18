import 'dart:io';
import 'dart:convert';
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
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _globalKey = GlobalKey();
  final List<String> _urlList = [];

  bool _showQr = false;
  String _data = "";

  @override
  void initState() {
    _urlController.addListener(() {
      setState(() {
        _data = jsonEncode({'urls': _urlList});
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
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
              child: Column(
                children: [
                  if (_showQr)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _showQr ? 1 : 0,
                      child: RepaintBoundary(
                        key: _globalKey,
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.white,
                          width: 300,
                          height: 300,
                          child: Center(
                            child: QrCodeGenerate(
                              data: _data,
                              qrSize: 300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  UrlInputField(
                    controller: _urlController,
                    formKey: _formKey,
                    onAdd: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _urlList.add(_urlController.text.replaceFirst(RegExp(r'https?://'), ''));
                          _urlController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  UrlListDisplay(
                    urlList: _urlList,
                    onRemove: (index) {
                      setState(() {
                        _urlList.removeAt(index);
                        _showQr = false;
                      });
                    },
                  ),
                  const SizedBox(height: 50),
                  QrButtonGroup(
                    showButtons: _showQr,
                    onGenerate: () {
                      if (_urlList.isNotEmpty) {
                        setState(() {
                          // _data = jsonEncode({'urls': _urlList.map((url) => Uri.parse(url).toString()).toList()});
                          _data = _urlList.join("\n");
                          _showQr = true;
                        });
                      }
                    },
                    onSave: _saveLocalImage,
                    onShare: _shareQrCode,
                  ),
                ],
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
      ByteData? byteData = await (image.toByteData(format: ui.ImageByteFormat.png));

      if (byteData != null) {
        final directory = await getTemporaryDirectory();
        final file = await File('${directory.path}/qr_code.png').create();
        await file.writeAsBytes(byteData.buffer.asUint8List());

        await Share.shareXFiles(
          [XFile(file.path)],
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
      ByteData? byteData = await (image.toByteData(format: ui.ImageByteFormat.png));
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

class UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final VoidCallback onAdd;

  const UrlInputField({
    required this.controller,
    required this.formKey,
    required this.onAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Put your link here',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter at least one link';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onAdd,
          child: const Text("Add link"),
        ),
      ],
    );
  }
}

class UrlListDisplay extends StatelessWidget {
  final List<String> urlList;
  final Function(int) onRemove;

  const UrlListDisplay({
    required this.urlList,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return urlList.isNotEmpty
        ? Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(
          urlList.length,
              (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    urlList[index],
                  ),
                ),
                GestureDetector(
                  onTap: () => onRemove(index),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        : const SizedBox();
  }
}

class QrButtonGroup extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool showButtons;

  const QrButtonGroup({
    required this.onGenerate,
    required this.onSave,
    required this.onShare,
    this.showButtons=false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onGenerate,
          child: const Text("Generate QR"),
        ),
        const SizedBox(height: 8),
        if(showButtons)...[ElevatedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.download),
          label: const Text("Download QR"),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share),
          label: const Text("Share QR"),
        ),]
      ],
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