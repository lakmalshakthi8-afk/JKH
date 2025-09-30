import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vestaigrade/screens/add_supplier_screen.dart';
import 'package:vestaigrade/screens/manage_emails.dart';
import 'package:vestaigrade/screens/new_library_screen.dart';
import 'package:vestaigrade/screens/supplier_list_screen.dart';
import 'package:vestaigrade/screens/supplier_selection_screen.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  int _repeatIndex = 0;
  final _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _initDetector();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _repeatIndex++;
          });
          if (_repeatIndex < 5) {
            _controller.reset();
            _controller.forward();
          }
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10.0,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                      ),
                      Image.asset('assets/images/logo1.png'),
                      // DefaultElevatedButton(
                      //   onPressed: () => _openCamera(),
                      //   title: "CAMERA",
                      //   icon: Icon(Icons.camera_alt_outlined),
                      // ),
                      // DefaultElevatedButton(
                      //   onPressed: () => _pickImage(),
                      //   title: "GALLERY",
                      //   icon: Icon(Icons.upload_file_outlined),
                      // ),
                      DefaultElevatedButton(
                        title: 'DETECT',
                        icon: Icon(Icons.image),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupplierSelectionScreen(),
                          ),
                        ),
                      ),
                      DefaultElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewLibraryScreen(),
                          ),
                        ),
                        title: "LIBRARY",
                        icon: Icon(Icons.folder_open_outlined),
                      ),
                      DefaultElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupplierListScreen(),
                          ),
                        ),
                        title: "SUPPLIER LIST",
                        icon: Icon(Icons.supervised_user_circle),
                      ),
                      DefaultElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => Container(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context)
                                      .viewInsets
                                      .bottom, // 👈 shifts content up
                                  left: 15,
                                  right: 15,
                                  top: 15,
                                ),
                                child: Column(
                                  spacing: 10.0,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Form(
                                      child: CustomTextFormField(
                                        controller: _passwordController,
                                        label: "Password",
                                      ),
                                    ),
                                    DefaultElevatedButton(
                                        title: "OK",
                                        onPressed: () {
                                          final pass =
                                              dotenv.env['PASSWORD'] ?? "";
                                          if (_passwordController.text ==
                                              pass) {
                                            _passwordController.clear();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ManageEmails(),
                                              ),
                                            );
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: "Incorrect Password");
                                          }
                                        })
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        title: "EMAIL LIST",
                        icon: Icon(Icons.email),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                    ],
                  ),
                ),
        ));
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }
}
