//uplooods menus
//inside a menu their is option to add button
// save data of menu to firebase
//edit and delete menu

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis_fragrances/admin_files/upload_button_screen.dart';

import '../utils/const.dart';

class UploadMenuScreen extends StatefulWidget {
  final String? menuId;
  final String? menuName;
  final String? menuImage;
  final bool isSpanish; // Added parameter for language control

  const UploadMenuScreen({
    Key? key,
    this.menuId,
    this.menuName,
    this.menuImage,
    this.isSpanish = false, // Default to English
  }) : super(key: key);

  @override
  _UploadMenuScreenState createState() => _UploadMenuScreenState();
}

class _UploadMenuScreenState extends State<UploadMenuScreen> {
  final TextEditingController _menuNameController = TextEditingController();
  final TextEditingController _sortOrderController =
      TextEditingController(); // Added sort order controller
  String? _menuImageUrl;
  String? _editingMenuId;
  bool _isEditing = false;
  bool _isUploading = false;
  PlatformFile? _webImage; // For web image
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.menuId != null) {
      _menuNameController.text = widget.menuName!;
      _menuImageUrl = widget.menuImage;
      _editingMenuId = widget.menuId;
      _isEditing = true;
      // Set the existing sort order if editing
      _sortOrderController.text = widget.menuName!; // Set the correct value
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // For web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _webImage = result.files.first;
          _webImageBytes = _webImage!.bytes;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSpanish
                ? 'No se seleccionó archivo.'
                : 'No file selected.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } else {
      // For mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('menus')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(pickedFile.path));
        final imageUrl = await ref.getDownloadURL();
        setState(() {
          _menuImageUrl = imageUrl;
        });
      }
    }
  }

  Future<void> _uploadMenu() async {
    if (_menuNameController.text.isNotEmpty &&
        (_menuImageUrl != null || _webImageBytes != null) &&
        _sortOrderController.text.isNotEmpty) {
      // Ensure sort order is provided
      setState(() {
        _isUploading = true;
      });

      String? uploadedImageUrl;

      try {
        if (kIsWeb && _webImageBytes != null) {
          final ref = FirebaseStorage.instance.ref().child('menus').child(
              '${DateTime.now().millisecondsSinceEpoch}_${_webImage!.name}');
          await ref.putData(_webImageBytes!);
          uploadedImageUrl = await ref.getDownloadURL();
        } else if (_menuImageUrl != null) {
          uploadedImageUrl = _menuImageUrl;
        }

        if (_isEditing) {
          await FirebaseFirestore.instance
              .collection('menus')
              .doc(_editingMenuId)
              .update({
            'menu_name': _menuNameController.text,
            'menu_image': uploadedImageUrl,
            'sort_order':
                int.tryParse(_sortOrderController.text) ?? 0, // Save sort order
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isSpanish
                  ? '¡Menú actualizado con éxito!'
                  : 'Menu updated successfully!'),
            ),
          );
        } else {
          await FirebaseFirestore.instance.collection('menus').add({
            'menu_name': _menuNameController.text,
            'menu_image': uploadedImageUrl,
            'sort_order':
                int.tryParse(_sortOrderController.text) ?? 0, // Save sort order
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isSpanish
                  ? '¡Menú subido con éxito!'
                  : 'Menu uploaded successfully!'),
            ),
          );
        }

        setState(() {
          _isEditing = false;
          _menuImageUrl = null;
          _webImageBytes = null;
          _menuNameController.clear();
          _sortOrderController.clear(); // Clear sort order field
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSpanish
                ? 'Error al subir el menú.'
                : 'Failed to upload menu.'),
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteMenu(String menuId) async {
    try {
      await FirebaseFirestore.instance.collection('menus').doc(menuId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? '¡Menú eliminado con éxito!'
              : 'Menu deleted successfully!'),
        ),
      );

      // Clear the form fields after successful deletion
      setState(() {
        _menuNameController.clear(); // Clear the menu name field
        _menuImageUrl = null; // Reset the image URL
        _webImage = null; // Reset the selected web image
        _isEditing = false; // Reset the editing flag
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? 'Error al eliminar el menú.'
              : 'Failed to delete menu.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSpanish ? 'Subir Menú' : 'Upload Menu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('menus').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final menus = snapshot.data!.docs;

                  return Column(
                    children: menus.map((menu) {
                      final menuId = menu.id;
                      final menuName = menu['menu_name'];
                      final menuImage = menu['menu_image'];

                      return ListTile(
                        leading:
                            Image.network(menuImage, width: 50, height: 50),
                        title: Text(menuName),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SaveButtonScreen(
                                menuId: menuId,
                                menuName: menuName,
                                isSpanish: widget.isSpanish,
                              ),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _menuNameController.text = menuName;
                                  _menuImageUrl = menuImage;
                                  _editingMenuId = menuId;
                                  _isEditing = true;
                                  _sortOrderController.text = menu['sort_order']
                                      .toString(); // Populate sort order
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteMenu(menuId),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _menuNameController,
                decoration: InputDecoration(
                  labelText: widget.isSpanish ? 'Nombre del Menú' : 'Menu Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isSpanish
                      ? 'Orden de clasificación'
                      : 'Sort Order',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _menuImageUrl == null && _webImage == null
                      ? Center(
                          child: Icon(Icons.add_a_photo, size: 50),
                        )
                      : (_webImage != null
                          ? Image.memory(_webImage!.bytes!, fit: BoxFit.cover)
                          : Image.network(_menuImageUrl!, fit: BoxFit.cover)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadMenu,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing
                            ? (widget.isSpanish
                                ? 'Actualizar Menú'
                                : 'Update Menu')
                            : (widget.isSpanish ? 'Subir Menú' : 'Upload Menu'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
