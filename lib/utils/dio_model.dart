import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:vestaigrade/utils/email_model.dart';

class EngineMailerService {
  final Dio _dio;
  final String apiKey;

  EngineMailerService({
    required this.apiKey,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  Future<bool> sendEmail(EngineEmail email) async {
    const url = 'https://api.enginemailer.com/RESTAPI/V2/Submission/SendEmail';
    try {
      final response = await _dio.post(
        url,
        data: email.toJson(),
        options: Options(
          method: "SendEmail",
          headers: {
            'APIKey': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (response.statusCode == 200 && data['Result'] != null) {
        final result = data['Result'];
        if (result['StatusCode'] == '200' && result['Status'] == 'OK') {
          print(
              '✅ Email sent successfully. Transaction ID: ${result["TransactionID"]}');
          return true;
        } else {
          print('❌ API responded with failure: $result');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode} -> $data');
      }
    } catch (e) {
      print('❌ Exception while sending email: $e');
    }
    return false;
  }
}
