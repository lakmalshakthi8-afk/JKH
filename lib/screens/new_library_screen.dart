import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/screens/report_detail_screen.dart';
import 'package:vestaigrade/utils/library_model.dart';
import 'package:tiny_db/tiny_db.dart';

class NewLibraryScreen extends StatefulWidget {
  const NewLibraryScreen({super.key});

  @override
  State<NewLibraryScreen> createState() => _NewLibraryScreenState();
}

class _NewLibraryScreenState extends State<NewLibraryScreen> {
  TinyDb? db;

  Future<List<LibraryModel>> _getData() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    db = TinyDb(JsonStorage("${appDirectory.path}/library.json"));
    final table = db!.table('library');
    final data = await table.all();
    List<LibraryModel> libraryList = [];
    //print(data);
    for (int i = 0; i < data.length; i++) {
      libraryList.add(LibraryModel.fromMap(data[i]));
    }

    return libraryList;
  }

  Future<void> _delete(DateTime date) async {
    if (db != null) {
      final table = db!.table('library');

      await table.remove(where('date').equals(date.millisecondsSinceEpoch));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('Library'),
        ),
        body: FutureBuilder(
            future: _getData(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                );
              } else if (snap.connectionState == ConnectionState.done &&
                  snap.data != null) {
                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ListView.builder(
                      itemCount: snap.data!.length,
                      itemBuilder: (context, index) {
                        final data = snap.data![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailScreen(
                                  library: data,
                                ),
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadiusGeometry.circular(15.0)),
                              tileColor: Colors.white10,
                              textColor: Colors.white,
                              iconColor: Colors.white,
                              title: Text(data.supplier!),
                              subtitle: Text(
                                  "${data.date.day}.${data.date.month}.${data.date.year}"),
                              trailing: SizedBox(
                                width: 150.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.image),
                                    Text(
                                      data.images.length.toString(),
                                    ),
                                    SizedBox(
                                      width: 10.0,
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(data.date),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                );
              } else {
                return SizedBox();
              }
            }),
      ),
    );
  }
}
