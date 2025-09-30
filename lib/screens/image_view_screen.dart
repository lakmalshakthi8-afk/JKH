import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vestaigrade/screens/library_screen.dart';

class ImageViewScreen extends StatefulWidget {
  const ImageViewScreen({super.key, required this.image});
  final File image;
  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  Future<void> deleteFile(String filePath) async {
    try {
      // Check if the file exists
      final file = File(filePath);
      if (await file.exists()) {
        // Delete the file
        await file.delete();
        Fluttertoast.showToast(
          msg: 'File deleted',
          backgroundColor: Colors.white,
          textColor: Colors.black,
        );
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LibraryScreen()),
            (route) => route.isFirst,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Something went wrong',
          backgroundColor: Colors.white,
          textColor: Colors.black,
        );
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.image.path.split('/').last),
        actions: [
          IconButton(
            onPressed: () => deleteFile(widget.image.path),
            icon: Icon(
              Icons.delete,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Image.file(
            widget.image,
          ),
        ),
      ),
    ));
  }
}
