import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/screens/new_result_screen.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';

class SupplierSelectionScreen extends StatefulWidget {
  const SupplierSelectionScreen({super.key});

  @override
  State<SupplierSelectionScreen> createState() =>
      _SupplierSelectionScreenState();
}

class _SupplierSelectionScreenState extends State<SupplierSelectionScreen> {
  List<Map> suppliers = [];
  bool isLoading = false;
  String selectedSupplier = '';

  _loadSuppliers() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table = db.table('suppliers');
    final list = await table.all();
    await db.close();
    setState(() {
      suppliers = list;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedSupplier = '';
    _loadSuppliers();
    // _initDetector();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'SELECT SUPPLIER',
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  spacing: 15.0,
                  children: [
                    DropdownMenu(
                      width: double.infinity,
                      textStyle: TextStyle(
                        color: Colors.white,
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        suffixIconColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(40.0),
                        ),
                      ),
                      dropdownMenuEntries: suppliers
                          .map(
                            (item) => DropdownMenuEntry(
                              value: item['code'],
                              label: item['name'],
                            ),
                          )
                          .toList(),
                      onSelected: (value) => selectedSupplier = value,
                    ),
                    DefaultElevatedButton(
                      onPressed: () => selectedSupplier.isNotEmpty
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewResultScreen(
                                  isCamera: true,
                                  supplier: selectedSupplier,
                                ),
                              ),
                            )
                          : null,
                      title: "CAMERA",
                      icon: Icon(Icons.camera_alt_outlined),
                    ),
                    DefaultElevatedButton(
                      onPressed: () => selectedSupplier.isNotEmpty
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewResultScreen(
                                  isCamera: false,
                                  supplier: selectedSupplier,
                                ),
                              ),
                            )
                          : null,
                      title: "GALLERY",
                      icon: Icon(Icons.upload_file_outlined),
                    ),
                  ],
                ),
              ),
            ),
    ));
  }
}
