//upload the data inside a menu
// save buttons insidemenu collection
//edit existing buttons

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/const.dart';

class SaveButtonScreen extends StatefulWidget {
  final String menuId;
  final bool isSpanish;

  const SaveButtonScreen({
    required this.menuId,
    required this.isSpanish,
    Key? key,
    required menuName,
  }) : super(key: key);

  @override
  _SaveButtonScreenState createState() => _SaveButtonScreenState();
}

class _SaveButtonScreenState extends State<SaveButtonScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();

  File? _pickedImage;
  bool _isUploading = false;
  String? _currentImageUrl;
  PlatformFile? _webImage; // For web image
  Uint8List? _webImageBytes;

  final ImagePicker _imagePicker = ImagePicker();

  Stream<QuerySnapshot> _fetchLinks() {
    return FirebaseFirestore.instance
        .collection('menus')
        .doc(widget.menuId)
        .collection('buttons')
        .snapshots();
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
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImageToStorage(File image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('button_images').child(fileName);

      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<String?> _uploadWebImageToStorage(Uint8List imageBytes) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('button_images').child(fileName);

      final uploadTask = storageRef.putData(imageBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading web image: $e");
      return null;
    }
  }

  Future<void> _deleteImageFromStorage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      } catch (e) {
        print("Error deleting image from storage: $e");
      }
    }
  }

  Future<void> _saveToFirestore(String imageUrl) async {
    try {
      final buttonName = _titleController.text.trim();
      final buttonLink = _linkController.text.trim();
      int? sortOrder = int.tryParse(_sortOrderController.text.trim());

      // Save button inside the menu collection as a new document
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(widget.menuId)
          .collection('buttons')
          .add({
        'name': buttonName, // Saving name as the button name
        'link': buttonLink,
        'sort_order': sortOrder ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "¡Datos subidos con éxito!"
              : "Data uploaded successfully!"),
        ),
      );
    } catch (e) {
      print("Error saving data to Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "Error al guardar los datos."
              : "Error saving data."),
        ),
      );
    }
  }

  Future<void> _deleteLink(String id, String imageUrl) async {
    try {
      await _deleteImageFromStorage(imageUrl);
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(widget.menuId)
          .collection('buttons')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "¡Enlace eliminado con éxito!"
              : "Link deleted successfully!"),
        ),
      );
    } catch (e) {
      print("Error deleting link: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "Error al eliminar el enlace."
              : "Error deleting link."),
        ),
      );
    }
  }

  Future<void> _uploadData() async {
    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImageToStorage(_pickedImage!);
    } else if (_webImageBytes != null) {
      imageUrl = await _uploadWebImageToStorage(_webImageBytes!);
    }

    if (imageUrl != null) {
      await _saveToFirestore(imageUrl);

      // Clear the fields after successful upload
      setState(() {
        _titleController.clear();
        _linkController.clear();
        _sortOrderController.clear();

        _pickedImage = null;
        _isUploading = false;
      });
    } else {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpanish = widget.isSpanish;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? 'Subir Enlaces' : 'Upload Links',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                    labelText: isSpanish ? "Título" : "Button Name"),
              ),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                    labelText: isSpanish ? "Enlace" : "Button Link"),
              ),
              TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      isSpanish ? "Orden de Clasificación" : "Sort Order",
                  hintText: isSpanish ? "Ingrese un número" : "Enter a number",
                ),
              ),
              const SizedBox(height: 16),
              _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _pickedImage!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _webImageBytes != null
                      ? Image.memory(
                          _webImageBytes!,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                      : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? Image.network(
                              _currentImageUrl!,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.broken_image),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(isSpanish ? "Seleccionar Imagen" : "Pick Image"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        await _uploadData(); // Upload data and clear fields
                      },
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : Text(isSpanish ? "Subir" : "Upload"),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _fetchLinks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(isSpanish
                            ? "No se han subido enlaces todavía."
                            : "No links uploaded yet."));
                  }

                  final links = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final button = links[index];
                      final buttonId = button.id;
                      final buttonName = button['name'] ?? '';
                      final buttonLink = button['link'] ?? '';
                      final buttonImageUrl = button['imageUrl'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditLinkScreen(
                                isSpanish: isSpanish,
                                linkId: buttonId,
                                menuId: widget.menuId, // Pass the menuId here
                                oldTitle: buttonName,
                                oldLink: buttonLink,
                                oldSortOrder: button['sort_order'] ?? 0,
                                oldImageUrl: buttonImageUrl,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                buttonImageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          buttonImageUrl,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.broken_image),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        buttonName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        buttonLink,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _deleteLink(buttonId, buttonImageUrl),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditLinkScreen extends StatefulWidget {
  final String linkId;
  final String menuId;
  final String oldTitle;
  final String oldLink;
  final int oldSortOrder;
  final String oldImageUrl;
  final bool isSpanish; // Add this field to receive the sort order

  const EditLinkScreen({
    Key? key,
    required this.linkId,
    required this.menuId,
    required this.oldTitle,
    required this.oldLink,
    required this.oldSortOrder,
    required this.oldImageUrl,
    required this.isSpanish,
  }) : super(key: key);

  @override
  State<EditLinkScreen> createState() => _EditLinkScreenState();
}

class _EditLinkScreenState extends State<EditLinkScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();
  File? _pickedImage;
  String? _currentImageUrl;
  PlatformFile? _webImage; // For web image
  Uint8List? _webImageBytes;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.oldTitle;
    _linkController.text = widget.oldLink;
    _currentImageUrl = widget.oldImageUrl;
    _sortOrderController.text = widget.oldSortOrder.toString();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _webImage = result.files.first;
          _webImageBytes = _webImage?.bytes;
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
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _editLink() async {
    await FirebaseFirestore.instance
        .collection('menus')
        .doc(widget.menuId) // Using the passed menuId here
        .collection('buttons')
        .doc(widget.linkId)
        .update({
      'name': _titleController.text.trim(),
      'link': _linkController.text.trim(),
      'imageUrl': _pickedImage != null
          ? await _uploadImageToStorage(_pickedImage!)
          : _currentImageUrl,
      'sort_order': int.tryParse(_sortOrderController.text) ??
          0, // Save the new sort order
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Future<String?> _uploadImageToStorage(File image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('button_images').child(fileName);

      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpanish = widget.isSpanish;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? "Editar Enlace" : "Edit Link",
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
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                  labelText: isSpanish ? "Título" : "Button Name"),
            ),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                  labelText: isSpanish ? "Enlace" : "Button Link"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sortOrderController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSpanish
                    ? "Orden de clasificación"
                    : "Sort Order", // New field for sort order
              ),
            ),
            _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _pickedImage!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? Image.network(
                        _currentImageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : Text(isSpanish
                        ? "Ninguna imagen seleccionada."
                        : "No image selected."),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(isSpanish ? "Seleccionar Imagen" : "Pick Image"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _editLink,
              child: Text(isSpanish ? "Actualizar" : "Update"),
            ),
          ],
        ),
      ),
    );
  }
}
