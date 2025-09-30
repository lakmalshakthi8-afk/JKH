// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:image/image.dart' as image_lib;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:vestaigrade/utils/library_model.dart';
// import 'package:vestaigrade/widgets/default_elevated_button.dart';
// import 'package:tiny_db/tiny_db.dart';
// import '../utils/detector_services.dart';

// class ResultScreen extends StatefulWidget {
//   const ResultScreen(
//       {super.key, required this.result, required this.code, this.library});
//   final Map result;
//   final String code;
//   final LibraryModel? library;
//   @override
//   State<ResultScreen> createState() => _ResultScreenState();
// }

// class _ResultScreenState extends State<ResultScreen>
//     with TickerProviderStateMixin {
//   Detector? _detector;
//   bool isLoading = true;
//   String? recognitions;
//   image_lib.Image? im;
//   Uint8List? memoryImage;
//   double? score;
//   late final AnimationController _controller;
//   int _repeatIndex = 0;
//   String? savePath;
//   ScreenshotController screenshotController = ScreenshotController();
//   Map<String, dynamic> supplier = {};

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final image = await picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       _detector!.processFrame(image);
//     }
//   }

//   // Future<void> _openCamera() async {
//   //   final picker = ImagePicker();
//   //   final image = await picker.pickImage(source: ImageSource.camera);
//   //   if (image != null) {
//   //     _detector!.processFrame(image);
//   //   }
//   // }

//   Future<void> _initDetector() async {
//     Map res = {};
//     _detector = await Detector.start();
//     _detector!.resultsStream.stream.listen((result) async {
//       setState(() {
//         final recognitions = result['recognitions'];
//         final im = result['image'];
//         final score = result['score'];
//         final memoryImage = _getImage(im);
//         res = {
//           'recognition': recognitions,
//           'score': score,
//           'image': memoryImage
//         };
//       });
//       await Future.delayed(
//         Duration(seconds: 1),
//       );
//       if (mounted) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ResultScreen(
//               result: res,
//               code: widget.code,
//             library: ,
//             ),
//           ),
//         ).then((_) {
//           setState(() {
//             isLoading = false;
//           });
//         });
//       }
//     });
//   }

//   Uint8List? _getImage(ima) {
//     if (ima != null) {
//       final image = image_lib.encodeBmp(ima!);
//       return image.buffer.asUint8List();
//     } else {
//       return null;
//     }
//   }

//   Future<String> _saveImageToAppDocumentDirectory(Uint8List imageBytes) async {
//     try {
//       // Get the application documents directory
//       final directory = await getApplicationDocumentsDirectory();

//       // Create the full path for the file
//       final filePath = '${directory.path}/${DateTime.now().toString()}.png';

//       // Write the file
//       final file = File(filePath);
//       await file.writeAsBytes(imageBytes);
//       // Fluttertoast.showToast(
//       //   msg: 'Image Saved!',
//       //   backgroundColor: Colors.white,
//       //   textColor: Colors.black,
//       // );
//       return filePath;
//     } catch (e) {
//       // Handle errors
//       throw Exception('Error saving image: $e');
//     }
//   }

//   Future<String> _captureImage() async {
//     final image = await screenshotController.capture();
//     if (image != null) {
//       final path = await _saveImageToAppDocumentDirectory(image);
//       return path;
//     } else {
//       return '';
//     }
//   }

//   Future<void> _getSupplier() async {
//     final appDirectory = await getApplicationDocumentsDirectory();
//     final db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
//     final table = db.table('suppliers');
//     final sup = await table.get(where('code').equals(widget.code));
//     if (sup != null) {
//       setState(() {
//         supplier = sup;
//       });
//     }
//   }

//   Future<void> _share() async {
//     final params = ShareParams(
//         title: 'Results',
//         text:
//             'Supplier Name: ${supplier['name']} \nCode: ${supplier['code']}\nItem: ${supplier['item']}\nDate and Time: ${DateTime.now()}\nGrade: ${widget.result['recognition'].toUpperCase()}\nProbability: ${(widget.result['score'] * 100.00).toStringAsFixed(2)} %');
//     final result = SharePlus.instance.share(params);
//   }

//   Future<LibraryModel> _addtoReport() async {
//     final path = await _captureImage();
//     if (widget.library != null) {
//       widget.library!.images.add(path);
//       widget.library!.results.add(widget.result['recognition'].toUpperCase());
//       return widget.library!;
//     } else {
//       final lb = LibraryModel(
//           DateTime.now(),
//           [path],
//           [widget.result['recognition'].toUpperCase()],
//           SupplierModel(supplier['name'], supplier['code'], supplier['item']));
//       return lb;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initDetector();
//     _getSupplier();
//     _controller = AnimationController(vsync: this)
//       ..addStatusListener((status) {
//         if (status == AnimationStatus.completed) {
//           setState(() {
//             _repeatIndex++;
//           });
//           if (_repeatIndex < 5) {
//             _controller.reset();
//             _controller.forward();
//           }
//         }
//       });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: widget.result.isNotEmpty
//           ? Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 spacing: 10.0,
//                 children: [
//                   Expanded(
//                     child: Screenshot(
//                       controller: screenshotController,
//                       child: DecoratedBox(
//                         decoration: BoxDecoration(color: Colors.black),
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             children: [
//                               widget.result['image'] != null
//                                   ? Expanded(
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           image: DecorationImage(
//                                             image: MemoryImage(
//                                                 widget.result['image']!),
//                                             fit: BoxFit
//                                                 .cover, // Adjust the fit mode (e.g., BoxFit.contain or BoxFit.fill)
//                                           ),
//                                         ),
//                                       ),
//                                       // child: CircleAvatar(
//                                       //   maxRadius: double.infinity,
//                                       //   backgroundImage: MemoryImage(
//                                       //     widget.result['image']!,
//                                       //   ),
//                                       // ),
//                                     )
//                                   : const SizedBox(),
//                               Text(
//                                 'RESULTS',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               widget.result['recognition'] != null
//                                   ? Text(
//                                       widget.result['recognition']
//                                           .toUpperCase(),
//                                       style: TextStyle(
//                                         fontSize: 25.0,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : const SizedBox(),
//                               Text(
//                                 'PROBABILITY',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               widget.result['score'] != null
//                                   ? Text(
//                                       '${(widget.result['score'] * 100.00).toStringAsFixed(2)} %',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : const SizedBox(),
//                               supplier.isNotEmpty
//                                   ? Text(
//                                       supplier['name'],
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : const SizedBox(),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   DefaultElevatedButton(
//                     title: 'Add to Report & Capture Next',
//                     onPressed: () {},
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     spacing: 10.0,
//                     children: [
//                       IconButton(
//                         onPressed: () {
//                           Navigator.popUntil(context, (route) => route.isFirst);
//                         },
//                         icon: Icon(
//                           Icons.home_filled,
//                           color: Colors.white,
//                         ),
//                       ),
//                       DefaultElevatedButton(
//                         title: 'SAVE',
//                         onPressed: () {
//                           _captureImage();
//                         },
//                       ),
//                       DefaultElevatedButton(
//                         title: 'SHARE',
//                         onPressed: () {
//                           _share();
//                         },
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             )
//           : const SizedBox(),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.stop();
//     _controller.dispose();
//     super.dispose();
//   }
// }
