import 'dart:io';

import 'package:flutter/material.dart' hide Table, TableRow, TableCell;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vestaigrade/utils/library_model.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.library});
  final LibraryModel library;
  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool isLoading = false;
  final _secureStorage = const FlutterSecureStorage();
  Future<void> _share() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table = db.table('suppliers');
    final supplier =
        await table.get(where('name').equals(widget.library.supplier));
    await db.close();

    if (supplier != null) {
      // Create formatted results string
      final resultsTable = widget.library.results.asMap().entries.map((entry) {
        final index = entry.key;
        final grade = widget.library.results[index] ?? 'N/A';
        final weight = widget.library.weight[index] ?? '0';
        final probability = widget.library.probabilities[index] ?? '0';
        return '${grade} | ${weight} Kg | ${probability}%';
      }).join('\n');

      final totalWeight = widget.library.weight
          .map((w) => double.tryParse(w ?? '0') ?? 0.0)
          .fold(0.0, (sum, weight) => sum + weight);

      final params = ShareParams(
        title: 'VestaiGrade Quality Assessment Report',
        files: widget.library.images.map((item) => XFile(item!)).toList(),
        text: 'QUALITY ASSESSMENT REPORT\n\n'
            'Supplier Name: ${supplier['name']}\n'
            'Code: ${supplier['code']}\n'
            'Item: ${supplier['item']}\n'
            'Date and Time: ${DateTime.now()}\n\n'
            'ASSESSMENT RESULTS:\n'
            'Grade | Weight | Probability\n'
            '------------------------\n'
            '$resultsTable\n\n'
            'Total Weight: $totalWeight Kg',
      );
      final result = await SharePlus.instance.share(params);
      if (result.status == ShareResultStatus.success) {
        Fluttertoast.showToast(msg: 'Result Shared');
      }
    }
  }

  Future<void> _sendEmail() async {
    // Replace with your SMTP relay credentials

    setState(() {
      isLoading = true;
    });
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/email.json"));
    final table = db.table('email');
    final emails = await table.all();
    await db.close();
    final db2 = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table2 = db2.table('suppliers');
    final supplier =
        await table2.get(where('name').equals(widget.library.supplier));
    await db2.close();

  final password = await _secureStorage.read(key: 'smtp_password') ?? dotenv.env['EMAILPASSWORD'] ?? '';
  final username = await _secureStorage.read(key: 'smtp_username') ?? dotenv.env['EMAIL'] ?? '';
  final host = await _secureStorage.read(key: 'smtp_host') ?? dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  final portStr = await _secureStorage.read(key: 'smtp_port') ?? dotenv.env['SMTP_PORT'] ?? '587';
  final port = int.tryParse(portStr) ?? 587;
    if (emails.isNotEmpty && supplier != null) {
      final sendTo = emails.map((item) => item['email'] as String).toList();
// Example: Gmail SMTP (change for other providers)
      final SmtpServer smtpServer;
      if (host.contains('gmail')) {
        smtpServer = gmail(username, password);
      } else {
        smtpServer = SmtpServer(host, username: username, password: password, port: port);
      }

      // Build the message
      // Create HTML table for email
      String createHtmlTable() {
        var rows = widget.library.results.asMap().entries.map((entry) {
          final index = entry.key;
          final grade = widget.library.results[index] ?? '';
          final weight = widget.library.weight[index] ?? '';
          final probability = widget.library.probabilities[index] ?? '';
          return '''
            <tr>
              <td style="padding: 8px; border: 1px solid #ddd;">$grade</td>
              <td style="padding: 8px; border: 1px solid #ddd;">$weight Kg</td>
              <td style="padding: 8px; border: 1px solid #ddd;">$probability%</td>
            </tr>
          ''';
        }).join();

        return '''
          <table style="border-collapse: collapse; width: 100%; margin-bottom: 20px;">
            <tr style="background-color: #f2f2f2;">
              <th style="padding: 8px; border: 1px solid #ddd;">Grade</th>
              <th style="padding: 8px; border: 1px solid #ddd;">Weight</th>
              <th style="padding: 8px; border: 1px solid #ddd;">Probability</th>
            </tr>
            $rows
          </table>
        ''';
      }

      final totalWeight = widget.library.weight
          .map((w) => double.tryParse(w ?? '0') ?? 0.0)
          .fold(0.0, (sum, weight) => sum + weight);

      final message = Message()
        ..from = Address(username, 'VestaiGrade')
        ..recipients.addAll(sendTo)
        ..subject = 'VestaiGrade Quality Assessment Report'
        ..html = '''
          <h2>Quality Assessment Report</h2>
          <p><strong>Supplier Name:</strong> ${supplier['name']}</p>
          <p><strong>Code:</strong> ${supplier['code']}</p>
          <p><strong>Item:</strong> ${supplier['item']}</p>
          <p><strong>Date and Time:</strong> ${DateTime.now()}</p>
          
          <h3>Assessment Results</h3>
          ${createHtmlTable()}
          
          <p><strong>Total Weight:</strong> $totalWeight Kg</p>
        '''
        ..attachments = widget.library.images
            .map((im) => FileAttachment(File(im!)))
            .toList();

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
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              )
            : Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  title: Text('Report Detail'),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Supplier: ${widget.library.supplier!}",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Date: ${widget.library.date}",
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor:
                                    MaterialStateProperty.all(Colors.white10),
                                columns: [
                                  DataColumn(
                                    label: Text('Grade',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  DataColumn(
                                    label: Text('Weight',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  DataColumn(
                                    label: Text('Probability',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                rows: List.generate(
                                  widget.library.results.length,
                                  (index) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          widget.library.results[index] ??
                                              'N/A',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${widget.library.weight[index] ?? '0'} Kg',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${widget.library.probabilities[index] ?? '0'}%',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Total Weight: ${widget.library.weight.map((w) => double.tryParse(w ?? '0') ?? 0.0).fold(0.0, (sum, weight) => sum + weight)} Kg",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                          shrinkWrap: true,
                          itemCount: widget.library.images.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 0.55,
                            crossAxisCount: 3, // Number of thumbnails per row
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            return Image.file(
                              File(widget.library.images[index]!),
                            );
                          }),
                      DefaultElevatedButton(
                          title: 'SHARE', onPressed: () => _share()),
                      DefaultElevatedButton(
                          title: 'EMAIL', onPressed: () => _sendEmail())
                    ],
                  ),
                ),
              ));
  }
}
