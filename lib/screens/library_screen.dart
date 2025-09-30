import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/screens/image_view_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<File>> _imageFilesFuture;

  Future<List<File>> getSavedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(directory.path);

    // List only image files (filter by extension if needed)
    final imageFiles = imageDirectory
        .listSync()
        .where((item) => item is File && (item.path.endsWith('.png')))
        .map((item) => File(item.path))
        .toList();

    return imageFiles;
  }

  @override
  void initState() {
    super.initState();
    _imageFilesFuture = getSavedImages();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('LIBRARY'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FutureBuilder(
            future: _imageFilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: Colors.white,
                ));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading images'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No images found'));
              }
              final imageFiles = snapshot.data!;
              return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 0.55,
                    crossAxisCount: 3, // Number of thumbnails per row
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    final file = imageFiles[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewScreen(image: file),
                          ),
                        );
                      },
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                      ),
                    );
                  });
            },
          ),
        ),
      ),
    );
  }
}
