// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:image/image.dart' as image_lib;
// import 'package:tflite_flutter/tflite_flutter.dart';

// enum _Codes {
//   init,
//   busy,
//   ready,
//   detect,
//   result,
// }

// class _Command {
//   const _Command(this.code, {this.args});

//   final _Codes code;
//   final List<Object>? args;
// }

// class Detector {
//   static const String _modelPath = 'assets/model/model.tflite';
//   static const String _labelPath = 'assets/model/labels.txt';

//   Detector._(this._isolate, this._interpreter, this._labels);

//   final Isolate _isolate;
//   late final Interpreter _interpreter;
//   late final List<String> _labels;

//   late final SendPort _sendPort;

//   bool _isReady = false;

//   final StreamController<Map<String, dynamic>> resultsStream =
//       StreamController<Map<String, dynamic>>();

//   static Future<Detector> start() async {
//     final ReceivePort receivePort = ReceivePort();

//     final Isolate isolate =
//         await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

//     final Detector result = Detector._(
//       isolate,
//       await _loadModel(),
//       await _loadLabels(),
//     );
//     receivePort.listen((message) {
//       result._handleCommand(message as _Command);
//     });
//     return result;
//   }

//   static Future<Interpreter> _loadModel() async {
//     final interpreterOptions = InterpreterOptions();

//     if (Platform.isAndroid) {
//       interpreterOptions.addDelegate(XNNPackDelegate());
//     }

//     return Interpreter.fromAsset(
//       _modelPath,
//       options: interpreterOptions..threads = 4,
//     );
//   }

//   static Future<List<String>> _loadLabels() async {
//     return (await rootBundle.loadString(_labelPath)).split('\n');
//   }

//   void processFrame(XFile cameraImage) {
//     if (_isReady) {
//       _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
//     }
//   }

//   void _handleCommand(_Command command) {
//     switch (command.code) {
//       case _Codes.init:
//         _sendPort = command.args?[0] as SendPort;

//         RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
//         _sendPort.send(_Command(_Codes.init, args: [
//           rootIsolateToken,
//           _interpreter.address,
//           _labels,
//         ]));
//       case _Codes.ready:
//         _isReady = true;
//       case _Codes.busy:
//         _isReady = false;
//       case _Codes.result:
//         _isReady = true;
//         resultsStream.add(command.args?[0] as Map<String, dynamic>);
//       default:
//         debugPrint('Detector unrecognized command: ${command.code}');
//     }
//   }

//   void stop() {
//     _isolate.kill();
//   }
// }

// class _DetectorServer {
//   static const int mlModelInputSize = 224;

//   //static const double confidence = 0.8;
//   Interpreter? _interpreter;
//   List<String>? _labels;

//   _DetectorServer(this._sendPort);

//   final SendPort _sendPort;

//   static void _run(SendPort sendPort) {
//     ReceivePort receivePort = ReceivePort();
//     final _DetectorServer server = _DetectorServer(sendPort);
//     receivePort.listen((message) async {
//       final _Command command = message as _Command;
//       await server._handleCommand(command);
//     });

//     sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
//   }

//   Future<void> _handleCommand(_Command command) async {
//     switch (command.code) {
//       case _Codes.init:
//         RootIsolateToken rootIsolateToken =
//             command.args?[0] as RootIsolateToken;

//         BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
//         _interpreter = Interpreter.fromAddress(command.args?[1] as int);
//         _labels = command.args?[2] as List<String>;
//         _sendPort.send(const _Command(_Codes.ready));
//       case _Codes.detect:
//         _sendPort.send(const _Command(_Codes.busy));
//         _convertCameraImage(command.args?[0] as XFile);
//       default:
//         debugPrint('_DetectorService unrecognized command ${command.code}');
//     }
//   }

//   void _convertCameraImage(XFile cameraImage) {
//     var preConversionTime = DateTime.now().millisecondsSinceEpoch;

//     final path = cameraImage.path;
//     final bytes = File(path).readAsBytesSync();
//     final image = image_lib.decodeImage(bytes);

//     final results = analyseImage(image, preConversionTime);
//     _sendPort.send(_Command(_Codes.result, args: [results]));
//   }

//   Map<String, dynamic> analyseImage(
//       image_lib.Image? image, int preConversionTime) {
//     var conversionElapsedTime =
//         DateTime.now().millisecondsSinceEpoch - preConversionTime;

//     var preProcessStart = DateTime.now().millisecondsSinceEpoch;
//     final imageInput = image_lib.copyResize(
//       image!,
//       width: mlModelInputSize,
//       height: mlModelInputSize,
//     );
//     // final grayImage = image_lib.grayscale(imageInput);
//     // final blurred = image_lib.gaussianBlur(grayImage, radius: 3);
//     // final sobel = image_lib.sobel(blurred, amount: 3);
//     // final invertedImage = image_lib.invert(sobel);
//     // final threshouldImage =
//     //     image_lib.luminanceThreshold(invertedImage, threshold: 0.2, amount: 1);

//     // final imageMatrix = List.generate(
//     //   invertedImage.height,
//     //   (y) => List.generate(
//     //     imageInput.width,
//     //     (x) {
//     //       final pixel = imageInput.getPixel(x, y);

//     //       return [pixel.luminance / 255.0];
//     //     },
//     //   ),
//     // );
//     final imageMatrix = List.generate(
//         imageInput.height,
//         (y) => List.generate(imageInput.width, (x) {
//               final pixel = imageInput.getPixel(x, y);
//               return [
//                 (pixel.r),
//                 (pixel.g),
//                 (pixel.b),
//               ];
//             }));

//     var preProcessElapsedTime =
//         DateTime.now().millisecondsSinceEpoch - preProcessStart;

//     var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

//     final output = _runInference(imageMatrix);

//     final result = output.first.first as List<double>;

//     int index = 0;
//     double score = 0.0;
//     for (var i = 0; i < result.length; i++) {
//       if (result[i] > score) {
//         score = result[i];
//         index = i;
//       }
//     }

//     var inferenceElapsedTime =
//         DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

//     var totalElapsedTime =
//         DateTime.now().millisecondsSinceEpoch - preConversionTime;

//     return {
//       "recognitions": _labels![index],
//       "image": imageInput,
//       "score": score,
//       "stats": <String, String>{
//         'Conversion time:': conversionElapsedTime.toString(),
//         'Pre-processing time:': preProcessElapsedTime.toString(),
//         'Inference time:': inferenceElapsedTime.toString(),
//         'Total prediction time:': totalElapsedTime.toString(),
//         'Frame': '${image.width} X ${image.height}',
//       },
//     };
//   }

//   // Float32List _imageToByteListFloat32(
//   //     image_lib.Image image, int inputSize, double mean, double std) {
//   //   var convertedBytes = Float32List(inputSize * inputSize);
//   //   var buffer = Float32List.view(convertedBytes.buffer);
//   //   int pixelIndex = 0;
//   //   for (var i = 0; i < inputSize; i++) {
//   //     for (var j = 0; j < inputSize; j++) {
//   //       var pixel = image.getPixel(j, i);
//   //       buffer[pixelIndex++] = image_lib.getLuminance(pixel) / 255.0;
//   //     }
//   //   }
//   //   return convertedBytes.buffer.asFloat32List();
//   // }

//   List<List<Object>> _runInference(
//     List<List<List<num>>> imageMatrix,
//   ) {
//     final input = [imageMatrix];

//     final output = {
//       0: [List<num>.filled(3, 0)],
//       // 1: [List<num>.filled(25, 0)],
//       // 2: [List<num>.filled(25, 0)],
//       // 3: [0.0],
//     };
//     _interpreter!.runForMultipleInputs([input], output);
//     return output.values.toList();
//   }
// }
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}

class Detector {
  static const String _modelPath = 'assets/model/model.tflite';
  static const String _labelPath = 'assets/model/labels.txt';

  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;

  late final SendPort _sendPort;

  bool _isReady = false;

  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>();

  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();

    final Isolate isolate =
        await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      await _loadModel(),
      await _loadLabels(),
    );
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    return Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions..threads = 4,
    );
  }

  static Future<List<String>> _loadLabels() async {
    return (await rootBundle.loadString(_labelPath)).split('\n');
  }

  void processFrame(XFile cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;

        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case _Codes.ready:
        _isReady = true;
      case _Codes.busy:
        _isReady = false;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as Map<String, dynamic>);
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  void stop() {
    _isolate.kill();
  }
}

class _DetectorServer {
  static const int mlModelInputSize = 320;

  //static const double confidence = 0.8;
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });

    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        RootIsolateToken rootIsolateToken =
            command.args?[0] as RootIsolateToken;

        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_Codes.ready));
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as XFile);
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(XFile cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    final path = cameraImage.path;
    final bytes = File(path).readAsBytesSync();
    final image = image_lib.decodeImage(bytes);

    final results = analyseImage(image, preConversionTime);
    _sendPort.send(_Command(_Codes.result, args: [results]));
  }

  Map<String, dynamic> analyseImage(
      image_lib.Image? image, int preConversionTime) {
    var conversionElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;
    final imageInput = image_lib.copyResize(
      image!,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );

    final imageMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(imageInput.width, (x) {
              final pixel = imageInput.getPixel(x, y);
              return [
                (pixel.r),
                (pixel.g),
                (pixel.b),
              ];
            }));

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    final output = _runInference(imageMatrix);

    final result = output.last as List<num>;

// Create a list of tuples (value, index) with correct types
    List<MapEntry<num, int>> indexedNumbers = result
        .asMap()
        .entries
        .map((entry) => MapEntry<num, int>(entry.value, entry.key))
        .toList();

    // Sort the list in descending order based on the value
    indexedNumbers.sort((a, b) => b.key.compareTo(a.key));
    final Map<String, String> labelMap = {
      "288230376151711744": "Grade C",
      "144115188075855872": "Grade B-",
      "360287970189639680": "GradeL-B",
      "216172782113783808": "Grade B+",
      "72057594037927936": "Grade B",
      "0": "Grade A",
    };
    List boxes = [];
    List<String> label = [];
    List score = [];
    for (int i = 0; i < indexedNumbers.length; i++) {
      if (indexedNumbers.elementAt(i).key > 0.41) {
        boxes.add(output.first[indexedNumbers.elementAt(i).value]);
        String l = '';
        l = labelMap[output[1][indexedNumbers.elementAt(i).value].toString()] ??
            '';
        label.add(l);
        score.add(output.last[indexedNumbers.elementAt(i).value]);
      }
    }

    // int index = 0;
    // num score = 0.0;
    // for (var i = 0; i < result.length; i++) {
    //   if (result[i] > score) {
    //     score = result[i];
    //     index = i;
    //   }
    // }

    // print(output[1][index].toString() == '288230376151711744');
    // print(output[1][index].toString());

    // switch (output[1][index].toString()) {
    //   case '288230376151711744':
    //     label.add('GradeS B');
    //     break;
    //   case '0':
    //     label.add('GradeS B');
    //     break;
    //   case '216172782113783808':
    //     label.add('GradeS A');
    //     break;
    //   case '360287970189639680':
    //     label.add('GradeS B+');
    //     break;
    //   default:
    //     label.add('Unkown');
    //     break;
    // }
    // print(output[1][index + 1].toString());
    // switch (output[1][index + 1].toString()) {
    //   case '0':
    //     label.add('GradeL B');
    //     break;
    //   case '288230376151711744':
    //     label.add('GradeL B');
    //     break;
    //   case '72057594037927936':
    //     label.add('GradeL A');
    //     break;
    //   case '144115188075855872':
    //     label.add('GradeL B+');
    //     break;
    //   default:
    //     label.add('Unkown');
    //     break;
    // }

    var inferenceElapsedTime =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    var totalElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;
    print(score);
    return {
      // "recognitions": _labels![index],
      "recognitions": label,
      "box": boxes,
      "size": [image.width, image.height],
      "image": imageInput,
      "score": score,
      "stats": <String, String>{
        'Conversion time:': conversionElapsedTime.toString(),
        'Pre-processing time:': preProcessElapsedTime.toString(),
        'Inference time:': inferenceElapsedTime.toString(),
        'Total prediction time:': totalElapsedTime.toString(),
        'Frame': '${image.width} X ${image.height}',
      },
    };
  }

  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    final input = [imageMatrix];

    final output = {
      0: List<List>.filled(64, List<num>.filled(4, 0.0)),
      1: List<num>.filled(64, 0),
      2: List<num>.filled(64, 0),
      // 3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    // print(output.values.length);
    // print(output[2]);

    return output.values.toList();
  }
}
