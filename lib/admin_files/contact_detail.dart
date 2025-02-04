//contact us screen
//update existing contacts
// save contacts

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:oasis_fragrances/widgets/bar.dart';

class UpdateContactScreen extends StatefulWidget {
  final bool isSpanish;

  const UpdateContactScreen({super.key, required this.isSpanish});

  @override
  _UpdateContactScreenState createState() => _UpdateContactScreenState();
}

class _UpdateContactScreenState extends State<UpdateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController contactController = TextEditingController();
  TextEditingController whatsappController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController skypeController = TextEditingController();
  TextEditingController directionsController = TextEditingController();
  TextEditingController webLinkController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false; // Track saving progress
  String? docId;

  @override
  void initState() {
    super.initState();
    _fetchContactDetails();
  }

  Future<void> _fetchContactDetails() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Contact').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = snapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          docId = doc.id;
          contactController.text = data['contact_number'] ?? '';
          whatsappController.text = data['whatsapp_number'] ?? '';
          emailController.text = data['email'] ?? '';
          skypeController.text = data['skype'] ?? '';
          directionsController.text = data['directions'] ?? '';
          webLinkController.text = data['web_link'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isSpanish
                ? 'Error al obtener los detalles de contacto: $e'
                : 'Error fetching contact details: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveContactDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSaving = true; // Show progress bar while saving
      });

      try {
        Map<String, dynamic> contactData = {
          'contact_number': contactController.text,
          'whatsapp_number': whatsappController.text,
          'email': emailController.text,
          'skype': skypeController.text,
          'directions': directionsController.text,
          'web_link': webLinkController.text,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (docId == null) {
          DocumentReference ref = await FirebaseFirestore.instance
              .collection('Contact')
              .add(contactData);
          docId = ref.id;
        } else {
          await FirebaseFirestore.instance
              .collection('Contact')
              .doc(docId)
              .update(contactData);
        }

        setState(() {
          isSaving = false; // Hide progress bar once saved
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isSpanish
                  ? '¡Detalles de contacto guardados con éxito!'
                  : 'Contact details saved successfully!')),
        );
      } catch (e) {
        setState(() {
          isSaving = false; // Hide progress bar on error
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isSpanish
                  ? 'Error al guardar los detalles de contacto: $e'
                  : 'Error saving contact details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSpanish
              ? 'Actualizar detalles de contacto'
              : 'Update Contact Details',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: contactController,
                        label: widget.isSpanish
                            ? 'Ingrese el número de contacto'
                            : 'Enter Contact Number',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: whatsappController,
                        label: widget.isSpanish
                            ? 'Ingrese el número de WhatsApp'
                            : 'Enter WhatsApp Number',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: emailController,
                        label: widget.isSpanish
                            ? 'Ingrese el correo electrónico'
                            : 'Enter Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return widget.isSpanish
                                ? 'Por favor ingrese un correo electrónico'
                                : 'Please enter email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return widget.isSpanish
                                ? 'Por favor ingrese un correo electrónico válido'
                                : 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: skypeController,
                        label:
                            widget.isSpanish ? 'Ingrese Skype' : 'Enter Skype',
                      ),
                      _buildTextField(
                        controller: directionsController,
                        label: widget.isSpanish
                            ? 'Ingrese Direcciones'
                            : 'Enter Directions',
                        maxLines: 3,
                      ),
                      _buildTextField(
                        controller: webLinkController,
                        label: widget.isSpanish
                            ? 'Ingrese Enlace Web'
                            : 'Enter Web Link',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 20),
                      if (isSaving) linearProgress(),
                      ElevatedButton(
                        onPressed: saveContactDetails,
                        child: Text(
                          widget.isSpanish ? 'Guardar' : 'Save',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}
