import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vestaigrade/widgets/default_elevated_button.dart';
import 'package:tiny_db/tiny_db.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key, required this.edit, this.customer});
  final bool edit;
  final Map? customer;

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  void _saveSupplier() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final db = TinyDb(JsonStorage("${appDirectory.path}/supplier.json"));
    final table = db.table('suppliers');
    if (!widget.edit) {
      await table.insert({
        'name': nameController.text,
        'code': codeController.text,
        'item': itemController.text,
        'email': emailController.text,
      });
      nameController.clear();
      codeController.clear();
      itemController.clear();
      emailController.clear();
      await db.close();
      Fluttertoast.showToast(
        msg: 'Supplier Saved!',
        backgroundColor: Colors.white,
        textColor: Colors.black,
      );
    } else {
      await table.upsert({
        'name': nameController.text,
        'code': codeController.text,
        'item': itemController.text,
        'email': emailController.text,
      }, where('name').equals(widget.customer!['name']));
      Fluttertoast.showToast(
        msg: 'Supplier Updated!',
        backgroundColor: Colors.white,
        textColor: Colors.black,
      );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.edit && widget.customer != null) {
      nameController.text = widget.customer!['name'];
      itemController.text = widget.customer!['item'];
      codeController.text = widget.customer!['code'];
      emailController.text = widget.customer!['email'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('ADD SUPPLIER'),
        ),
        body: Form(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(children: [
                CustomTextFormField(
                  controller: nameController,
                  label: "Supplier Name",
                ),
                const SizedBox(
                  height: 20.0,
                ),
                CustomTextFormField(
                  controller: codeController,
                  label: "Supplier Code",
                ),
                const SizedBox(
                  height: 20.0,
                ),
                CustomTextFormField(
                  controller: itemController,
                  label: "Supplier Item",
                ),
                const SizedBox(
                  height: 20.0,
                ),
                CustomTextFormField(
                  controller: emailController,
                  label: "email",
                ),
                const SizedBox(
                  height: 20.0,
                ),
                DefaultElevatedButton(
                    title: 'ADD SUPPLIER', onPressed: () => _saveSupplier())
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField(
      {super.key, required this.controller, required this.label});
  final TextEditingController? controller;
  final String label;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
          label: Text(
            label,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide(
              color: Colors.green,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide(
              color: Colors.green,
            ),
          )),
    );
  }
}
