import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/screens/add_supplier_screen.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  TinyDb? db;
  Future<List<Map>> _getData() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table = db!.table('suppliers');
    final data = await table.all();

    return data;
  }

  Future<void> _delete(String code) async {
    if (db != null) {
      final table = db!.table('suppliers');

      await table.remove(where('name').equals(code));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "MANAGE SUPPLIERS",
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder(
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
                                  snap.data![index]['name'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  "${snap.data![index]['code']}- ${snap.data![index]['item']}\n ${snap.data![index]['email']}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: SizedBox(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddSupplierScreen(
                                              edit: true,
                                              customer: snap.data![index],
                                            ),
                                          ),
                                        ).then((_) => setState(() {})),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () =>
                                            _delete(snap.data![index]['name']),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                    } else {
                      return SizedBox();
                    }
                  }),
              DefaultElevatedButton(
                title: 'ADD SUPPLIERS',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSupplierScreen(
                      edit: false,
                    ),
                  ),
                ).then((_) => setState(() {})),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
