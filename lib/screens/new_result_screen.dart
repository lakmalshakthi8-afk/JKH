import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vestaigrade/screens/add_supplier_screen.dart';
import 'package:vestaigrade/utils/detector_services.dart';

import 'package:vestaigrade/utils/library_model.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';

class NewResultScreen extends StatefulWidget {
  const NewResultScreen({
    super.key,
    required this.supplier,
    required this.isCamera,
  });
  final String supplier;
  final bool isCamera;
  @override
  State<NewResultScreen> createState() => _NewResultScreenState();
}

class _NewResultScreenState extends State<NewResultScreen> {
  Detector? _detector;
  bool isLoading = false;
  Map data = {};
  final ScreenshotController screenshotController = ScreenshotController();
  LibraryModel? library;
  Map supplierData = {};
  final _weightController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _pickImage() async {
    setState(() {
      isLoading = true;
    });
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _detector!.processFrame(image);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openCamera() async {
    setState(() {
      isLoading = true;
    });
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _detector!.processFrame(image);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _captureImage() async {
    final image = await screenshotController.capture();
    if (image != null) {
      final path = await _saveImageToAppDocumentDirectory(image);
      return path;
    } else {
      return '';
    }
  }

  Future<String> _saveImageToAppDocumentDirectory(Uint8List imageBytes) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create the full path for the file
      final filePath = '${directory.path}/${DateTime.now().toString()}.png';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      // Fluttertoast.showToast(
      //   msg: 'Image Saved!',
      //   backgroundColor: Colors.white,
      //   textColor: Colors.black,
      // );
      return filePath;
    } catch (e) {
      // Handle errors
      throw Exception('Error saving image: $e');
    }
  }

  Future<void> _initDetector() async {
    _detector = await Detector.start();
    _detector!.resultsStream.stream.listen((result) async {
      setState(() {
        final recognitions = result['recognitions'];
        final im = result['image'];
        final score = result['score'];
        final memoryImage = _getImage(im);
        data = {
          'recognition': recognitions,
          'score': score,
          'image': memoryImage
        };
      });
      await Future.delayed(
        Duration(seconds: 1),
      );
      setState(() {
        isLoading = false;
      });
    });
  }

  Uint8List? _getImage(ima) {
    if (ima != null) {
      final image = image_lib.encodeBmp(ima!);
      return image.buffer.asUint8List();
    } else {
      return null;
    }
  }

  Future<void> _getSupplier() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table = db.table('suppliers');
    final sup = await table.get(where('code').equals(widget.supplier));
    if (sup != null) {
      setState(() {
        supplierData = sup;
      });
    }
  }

  Future<void> _addtoReport() async {
    final path = await _captureImage();

    if (library != null) {
      library!.images.add(path);
      library!.results.add(data['recognition'].first.toUpperCase());
      library!.probabilities
          .add((data['score'].first * 100.00).toStringAsFixed(2));
      library!.weight.add(_weightController.text);
    } else {
      library = LibraryModel(
        DateTime.now(),
        [path],
        [data['recognition'].first.toUpperCase()],
        [(data['score'].first * 100.00).toStringAsFixed(2)],
        supplierData['name'],
        [_weightController.text],
      );
    }
  }

  Future<void> _savetoLibrary() async {
    //await _addtoReport();
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/library.json"));
    final table = db.table('library');
    await table.insert(library!.toMap());
  }

  // Future<void> _sendEmail() async {
  //   final dio =
  //       EngineMailerService(apiKey: "6935fd7e-ce8a-4219-8040-4918a660499c");
  //   final email = EngineEmail(
  //       toEmail: "chathuracha@gmail.com",
  //       senderEmail: "rnd.welfare@gmail.com",
  //       subject: "test",
  //       submittedContent: "Test 01");
  //   final result = await dio.sendEmail(email);
  //   print('email result: $result');
  // }

  Future<void> _sendEmail() async {
    // Replace with your SMTP relay credentials
    if (_weightController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      final appDirectory = await getApplicationDocumentsDirectory();
      final db = TinyDb(JsonStorage("${appDirectory.path}/email.json"));
      final table = db.table('email');
      final emails = await table.all();
      await db.close();
      await _savetoLibrary();
    final password = await _secureStorage.read(key: 'smtp_password') ?? dotenv.env['EMAILPASSWORD'] ?? '';
    final username = await _secureStorage.read(key: 'smtp_username') ?? dotenv.env['EMAIL'] ?? '';
    final host = await _secureStorage.read(key: 'smtp_host') ?? dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
    final portStr = await _secureStorage.read(key: 'smtp_port') ?? dotenv.env['SMTP_PORT'] ?? '587';
    final port = int.tryParse(portStr) ?? 587;
      if (supplierData.isNotEmpty && library != null && emails.isNotEmpty) {
        final sendTo = emails.map((item) => item['email'] as String).toList();
// Example: Gmail SMTP (change for other providers)
        final SmtpServer smtpServer;
        if (host.contains('gmail')) {
          smtpServer = gmail(username, password);
        } else {
          smtpServer = SmtpServer(host, username: username, password: password, port: port);
        }

        // Build the message
        final message = Message()
          ..from = Address(username, 'Your App')
          ..recipients.addAll(sendTo)
          ..subject = 'Result'
          ..text =
              'Supplier Name: ${supplierData['name']}\nCode: ${supplierData['code']}\nItem: ${supplierData['item']}\nDate and Time: ${DateTime.now().toIso8601String()}\nGrade: ${library!.results.join(',')}\nProbability: ${library!.probabilities.join('%,')}%\nWeights:${library!.weight.join(',')}'
          ..attachments =
              library!.images.map((im) => FileAttachment(File(im!))).toList();

        try {
          final sendReport = await send(message, smtpServer);
          //  print('Message sent: $sendReport');
          Fluttertoast.showToast(msg: 'Message sent: $sendReport');
        } on MailerException catch (e) {
          //print('Message not sent. \n${e.toString()}');
          Fluttertoast.showToast(msg: 'Message not sent. \n${e.toString()}');
        }
      } else {
        Fluttertoast.showToast(msg: "No Emails or Data to send");
      }
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      Fluttertoast.showToast(msg: 'Weight is required');
    }
  }

  @override
  void initState() {
    super.initState();
    _initDetector();
    _getSupplier();
    if (widget.isCamera) {
      _openCamera();
    } else {
      _pickImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : data.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Screenshot(
                            controller: screenshotController,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.black),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    if (data['image'] != null)
                                      Container(
                                        height:
                                            250, // 👈 fixed height so it works inside scroll
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: MemoryImage(data['image']!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Text('RESULTS',
                                        style: TextStyle(color: Colors.white)),
                                    if (data['recognition'].isNotEmpty)
                                      Text(
                                        data['recognition'].first.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 25.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Text('PROBABILITY',
                                        style: TextStyle(color: Colors.white)),
                                    if (data['score'].isNotEmpty)
                                      Text(
                                        '${(data['score'].first * 100.00).toStringAsFixed(2)} %',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            child: CustomTextFormField(
                              controller: _weightController,
                              label: "Weight (kg)",
                            ),
                          ),
                          const SizedBox(height: 16),
                          DefaultElevatedButton(
                            title: 'Add to Report & Capture Next',
                            onPressed: () {
                              _addtoReport().then((_) => widget.isCamera
                                  ? _openCamera()
                                  : _pickImage());
                            },
                          ),
                          DefaultElevatedButton(
                            title: 'Recapture',
                            onPressed: () {
                              widget.isCamera ? _openCamera() : _pickImage();
                            },
                          ),
                          DefaultElevatedButton(
                            title: 'Finish and Save',
                            onPressed: () async {
                              if (data['recognition'].isNotEmpty) {
                                await _addtoReport();
                                await _sendEmail();
                              }
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.popUntil(
                                      context, (route) => route.isFirst);
                                },
                                icon: Icon(Icons.home_filled,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
      ),
    );
  }
}
