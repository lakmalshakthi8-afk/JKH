import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/screens/add_supplier_screen.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ManageEmails extends StatefulWidget {
  const ManageEmails({super.key});

  @override
  State<ManageEmails> createState() => _ManageEmailsState();
}

class _ManageEmailsState extends State<ManageEmails> {
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  TinyDb? db;

  Future<String> _sendEmail(String toEmail) async {
    try {
      final password = dotenv.env['EMAILPASSWORD'] ?? '';
      final username = dotenv.env['EMAIL'] ?? '';

      if (password.isEmpty || username.isEmpty) {
        return 'Error: Email configuration not found';
      }

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'VestaiGrade App')
        ..recipients.add(toEmail)
        ..subject = 'VestaiGrade Email Test'
        ..text =
            'This is a test email from VestaiGrade App.\n\nSent at: ${DateTime.now().toIso8601String()}';

      await send(message, smtpServer);
      return 'Email sent successfully';
    } catch (e) {
      return 'Error sending email: ${e.toString()}';
    }
  }

  Future<void> _saveEmail() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/email.json"));
    final table = db.table('email');
    await table.insert({
      'email': _emailController.text,
      'description': _descriptionController.text,
    });
    Fluttertoast.showToast(msg: "Email Saved");
    _emailController.clear();
    _descriptionController.clear();
    await db.close();
  }

  Future<List<Map>> _getData() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    db = TinyDb(JsonStorage("${appDirectory.path}/email.json"));
    final table = db!.table('email');
    final data = await table.all();

    return data;
  }

  Future<void> _delete(String code) async {
    if (db != null) {
      final table = db!.table('email');

      await table.remove(where('email').equals(code));
      setState(() {});
    }
  }

  Future<void> _testEmail(String email) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Testing Email'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending test email to: $email'),
          ],
        ),
      ),
    );

    final result = await _sendEmail(email);

    if (context.mounted) {
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor:
              result.startsWith('Error') ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          title: Text(
            "EMAIL LIST",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: FutureBuilder(
                  future: _getData(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      );
                    } else if (snap.connectionState == ConnectionState.done &&
                        snap.hasData) {
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snap.data!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadiusGeometry.circular(15.0)),
                                tileColor: Colors.white10,
                                title: Text(
                                  snap.data![index]['email'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  "${snap.data![index]['description']}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Test Email Button
                                    IconButton(
                                      onPressed: () => _testEmail(
                                          snap.data![index]['email']),
                                      icon: Icon(
                                        Icons.send,
                                        color: Colors.green,
                                      ),
                                    ),
                                    // Delete Button
                                    IconButton(
                                      onPressed: () =>
                                          _delete(snap.data![index]['email']),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                    } else {
                      return SizedBox();
                    }
                  }),
            ),
            DefaultElevatedButton(
                title: "ADD EMAIL",
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (bottomSheetContext) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context)
                                  .viewInsets
                                  .bottom, // for keyboard
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                color: Colors.black54,
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 10.0,
                                    children: [
                                      Form(
                                        child: Column(
                                          spacing: 10.0,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomTextFormField(
                                              controller: _emailController,
                                              label: "Email",
                                            ),
                                            CustomTextFormField(
                                              controller:
                                                  _descriptionController,
                                              label: "Description",
                                            ),
                                          ],
                                        ),
                                      ),
                                      DefaultElevatedButton(
                                          title: "Add",
                                          onPressed: () async {
                                            await _saveEmail();
                                            if (bottomSheetContext.mounted) {
                                              Navigator.pop(bottomSheetContext);
                                            }
                                          })
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ));
                })
          ],
        ),
      ),
    );
  }
}
