//These are the links displayed in home page below 2nd heading
//save and edit those links

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/const.dart';

class UploadLinksScreen extends StatefulWidget {
  final bool isSpanish;

  const UploadLinksScreen({Key? key, this.isSpanish = false}) : super(key: key);

  @override
  State<UploadLinksScreen> createState() => _UploadLinksScreenState();
}

class _UploadLinksScreenState extends State<UploadLinksScreen> {
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
    return FirebaseFirestore.instance.collection('links').snapshots();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
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

  Future<String?> _uploadImageToStorage() async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploaded_images')
          .child(fileName);

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        // For web, upload bytes
        uploadTask = storageRef.putData(
          _webImageBytes!,
          SettableMetadata(contentType: _webImage!.extension),
        );
      } else if (_pickedImage != null) {
        // For mobile, upload file
        uploadTask = storageRef.putFile(_pickedImage!);
      } else {
        throw Exception("No image selected for upload.");
      }

      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
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
      // Retrieve the sort order from the controller
      int? sortOrder = int.tryParse(_sortOrderController.text.trim());

      // Add the document to Firestore with the new field for sort order
      await FirebaseFirestore.instance.collection('links').add({
        'title': _titleController.text.trim(),
        'link': _linkController.text.trim(),
        'image_url': imageUrl,
        'sort_order':
            sortOrder ?? 0, // Default to 0 if no valid sort order is entered
        'created_at': FieldValue.serverTimestamp(),
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
      await FirebaseFirestore.instance.collection('links').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isSpanish
                ? "¡Enlace eliminado con éxito!"
                : "Link deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting link: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isSpanish
                ? "Error al eliminar el enlace."
                : "Error deleting link.")),
      );
    }
  }

  Future<void> _uploadData() async {
    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await _uploadImageToStorage();

    if (imageUrl != null) {
      await _saveToFirestore(imageUrl);
      print("Uploading data...");
      print("Image URL: $imageUrl");

      // Clear the fields after successful upload
      setState(() {
        _titleController.clear();
        _linkController.clear();
        _pickedImage = null;
        _webImageBytes = null;
        _sortOrderController.clear();
        _isUploading = false;
      });
    } else {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "Error al subir la imagen."
              : "Error uploading image."),
        ),
      );
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
                decoration:
                    InputDecoration(labelText: isSpanish ? "Título" : "Title"),
              ),
              TextField(
                controller: _linkController,
                decoration:
                    InputDecoration(labelText: isSpanish ? "Enlace" : "Link"),
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
                      var link = links[index];
                      String linkId = link.id;
                      String linkTitle = link['title'];
                      String linkUrl = link['link'];
                      String linkImageUrl = link['image_url'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditLinkScreen(
                                isSpanish: isSpanish,
                                linkId: linkId,
                                oldTitle: linkTitle,
                                oldLink: linkUrl,
                                oldImageUrl: linkImageUrl,
                                oldSortOrder: link['sort_order'] ??
                                    0, // Pass the sort order here
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
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: linkImageUrl.isNotEmpty
                                      ? Image.network(
                                          linkImageUrl,
                                          fit: BoxFit.cover,
                                          height: 180,
                                          width: double.infinity,
                                          color: Colors.black.withOpacity(0.4),
                                          colorBlendMode: BlendMode.darken,
                                        )
                                      : const Icon(Icons.broken_image),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Text(
                                    linkTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditLinkScreen(
                                                isSpanish: isSpanish,
                                                linkId: linkId,
                                                oldTitle: linkTitle,
                                                oldLink: linkUrl,
                                                oldImageUrl: linkImageUrl,
                                                oldSortOrder:
                                                    link['sort_order'] ?? 0,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.white),
                                        onPressed: () async {
                                          await _deleteLink(
                                              linkId, linkImageUrl);
                                        },
                                      ),
                                    ],
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

class EditLinkScreen extends StatefulWidget {
  final bool isSpanish;
  final String linkId;
  final String oldTitle;
  final String oldLink;
  final String oldImageUrl;
  final int oldSortOrder; // Add this field to receive the sort order

  const EditLinkScreen({
    Key? key,
    required this.isSpanish,
    required this.linkId,
    required this.oldTitle,
    required this.oldLink,
    required this.oldImageUrl,
    required this.oldSortOrder, // Initialize the new parameter
  }) : super(key: key);

  @override
  State<EditLinkScreen> createState() => _EditLinkScreenState();
}

class _EditLinkScreenState extends State<EditLinkScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _sortOrderController =
      TextEditingController(); // New controller for sortOrder
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
    _sortOrderController.text =
        widget.oldSortOrder.toString(); // Initialize with the old sort order
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

  Future<void> _editLink() async {
    await FirebaseFirestore.instance
        .collection('links')
        .doc(widget.linkId)
        .update({
      'title': _titleController.text.trim(),
      'link': _linkController.text.trim(),
      'image_url': _pickedImage != null
          ? await _uploadImageToStorage(_pickedImage!)
          : _currentImageUrl,
      'sort_order': int.tryParse(_sortOrderController.text) ??
          0, // Save the new sort order
      'updated_at': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Future<String?> _uploadImageToStorage(File image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploaded_images')
          .child(fileName);

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
                labelText: isSpanish ? "Título" : "Title",
              ),
            ),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: isSpanish ? "Enlace" : "Link",
              ),
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
              onPressed: _editLink,
              child: Text(isSpanish ? "Guardar" : "Save"),
            ),
          ],
        ),
      ),
    );
  }
}
