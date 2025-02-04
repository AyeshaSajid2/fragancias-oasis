//save headers to be displayed in the home screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';

class SaveHeadingsScreen extends StatefulWidget {
  final bool isSpanish; // Added parameter for language control

  const SaveHeadingsScreen({Key? key, this.isSpanish = false})
      : super(key: key);

  @override
  _SaveHeadingsScreenState createState() => _SaveHeadingsScreenState();
}

class _SaveHeadingsScreenState extends State<SaveHeadingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController heading1Controller = TextEditingController();
  final TextEditingController heading2Controller = TextEditingController();

  bool headingsExist = false;
  String? documentId;

  @override
  void initState() {
    super.initState();
    _loadSavedHeadings();
  }

  Future<void> _loadSavedHeadings() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('headings').limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs[0];
        var data = doc.data() as Map<String, dynamic>;

        setState(() {
          headingsExist = true;
          documentId = doc.id;
          heading1Controller.text = data['heading1'] ?? '';
          heading2Controller.text = data['heading2'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveHeadings() async {
    String heading1 = heading1Controller.text.trim();
    String heading2 = heading2Controller.text.trim();

    if (heading1.isNotEmpty && heading2.isNotEmpty) {
      try {
        if (headingsExist) {
          await _firestore.collection('headings').doc(documentId).update({
            'heading1': heading1,
            'heading2': heading2,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isSpanish
                    ? 'Encabezados actualizados con éxito!'
                    : 'Headings updated successfully!')),
          );
        } else {
          await _firestore.collection('headings').add({
            'heading1': heading1,
            'heading2': heading2,
            'createdAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.isSpanish
                    ? 'Encabezados guardados con éxito!'
                    : 'Headings saved successfully!')),
          );
        }

        heading1Controller.clear();
        heading2Controller.clear();
        _loadSavedHeadings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isSpanish
                ? '¡Por favor ingrese ambos encabezados!'
                : 'Please enter both headings!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryColor,
        title: Text(
          widget.isSpanish ? 'Ingresar Encabezados' : 'Enter Headings',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: heading1Controller,
              decoration: InputDecoration(
                labelText: widget.isSpanish
                    ? 'Ingresar 1er Encabezado'
                    : 'Enter 1st Heading',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: heading2Controller,
              decoration: InputDecoration(
                labelText: widget.isSpanish
                    ? 'Ingresar 2do Encabezado'
                    : 'Enter 2nd Heading',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _saveHeadings,
              child: Text(
                headingsExist
                    ? (widget.isSpanish ? 'Actualizar' : 'Update')
                    : (widget.isSpanish ? 'Guardar' : 'Save'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
