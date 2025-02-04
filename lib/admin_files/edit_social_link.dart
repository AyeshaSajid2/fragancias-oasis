//Social link input scree
//Save data to firebase
//update existing record
// /

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';

class EditSocialLinksScreen extends StatefulWidget {
  final bool isSpanish;

  const EditSocialLinksScreen({super.key, required this.isSpanish});

  @override
  State<EditSocialLinksScreen> createState() => _EditSocialLinksScreenState();
}

class _EditSocialLinksScreenState extends State<EditSocialLinksScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {
    'TikTok': TextEditingController(),
    'YouTube': TextEditingController(),
    'Instagram': TextEditingController(),
    'Pinterest': TextEditingController(),
    'Facebook': TextEditingController(),
    'Twitter': TextEditingController(),
    'LinkedIn': TextEditingController(),
  };

  bool isSaving = false;
  bool isLoading = false;
  bool isEditing = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadExistingLinks();
  }

  Future<void> _loadExistingLinks() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('social_links')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data.forEach((key, value) {
          if (_controllers.containsKey(key)) {
            _controllers[key]?.text = value;
          }
        });
        setState(() => isEditing = true);
      } else {
        setState(() => isEditing = true); // Allow editing if no data found
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveLinks() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isSaving = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = {
          for (var entry in _controllers.entries) entry.key: entry.value.text,
        };

        try {
          await FirebaseFirestore.instance
              .collection('social_links')
              .doc(user.uid)
              .set(data, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isSpanish
                    ? 'Enlaces guardados con éxito'
                    : 'Social links saved successfully',
              ),
            ),
          );
          setState(() {
            isEditing = false;
            isSaved = true; // Prevent further edits after saving
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isSpanish
                    ? 'Error al guardar los enlaces: $e'
                    : 'Error saving social links: $e',
              ),
            ),
          );
        } finally {
          setState(() => isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSpanish ? 'Editar enlaces sociales' : 'Edit Social Links',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          ..._controllers.entries.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: widget.isSpanish
                                      ? 'Enlace de ${entry.key}'
                                      : '${entry.key} Link',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return widget.isSpanish
                                        ? 'Por favor, introduzca el enlace de ${entry.key}'
                                        : 'Please enter ${entry.key} link';
                                  }
                                  return null;
                                },
                                enabled:
                                    isEditing, // Make it editable when data is fetched or is empty
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                isSaved ? null : _saveLinks, // Disable if saved
                            child: Text(
                              isEditing
                                  ? (widget.isSpanish
                                      ? 'Actualizar enlaces'
                                      : 'Update Links')
                                  : (widget.isSpanish
                                      ? 'Guardar enlaces'
                                      : 'Save Links'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
