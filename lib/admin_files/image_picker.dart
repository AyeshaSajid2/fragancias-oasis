// Complete Flutter code for the UpdateCrousalImageScreen widget.
//crousal image input screen '
//delete existing crousal images
// save new one
//can save upto 6 images

import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis_fragrances/utils/const.dart';

class UpdateCrousalImageScreen extends StatefulWidget {
  final bool isSpanish;

  const UpdateCrousalImageScreen({super.key, this.isSpanish = false});

  @override
  _UpdateCrousalImageScreenState createState() =>
      _UpdateCrousalImageScreenState();
}

class _UpdateCrousalImageScreenState extends State<UpdateCrousalImageScreen> {
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isUploading = false;
  String uniqueIdName = DateTime.now().millisecondsSinceEpoch.toString();
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('crousal_images').get();
      setState(() {
        imageUrls =
            snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
      });
    } catch (e) {
      print("Error loading images: $e");
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _webImage = result.files.first.bytes;
        });
      } else {
        _showSnackbar(
            widget.isSpanish
                ? 'No se seleccionó archivo.'
                : 'No file selected.',
            Colors.amber);
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxHeight: 720,
        maxWidth: 1280,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null && _webImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = uniqueIdName + '.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('crousal_images')
          .child(fileName);

      String imageUrl;

      if (kIsWeb && _webImage != null) {
        await ref.putData(_webImage!);
      } else if (_selectedImage != null) {
        await ref.putFile(_selectedImage!);
      }

      imageUrl = await ref.getDownloadURL();

      if (imageUrl.isNotEmpty) {
        if (imageUrls.length < 5) {
          await FirebaseFirestore.instance.collection('crousal_images').add({
            'imageUrl': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            imageUrls.add(imageUrl);
          });

          _showSnackbar(
              widget.isSpanish
                  ? '¡Imagen subida con éxito!'
                  : 'Image uploaded successfully!',
              Colors.green);
        } else {
          _showSnackbar(
              widget.isSpanish
                  ? '¡Solo puedes subir un máximo de 5 imágenes!'
                  : 'You can upload a maximum of 5 images!',
              Colors.red);
        }
      } else {
        throw 'Failed to get image URL';
      }
    } catch (e) {
      _showSnackbar(
          widget.isSpanish
              ? 'Error al subir la imagen: $e'
              : 'Error uploading image: $e',
          Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
        _webImage = null;
      });
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      final snapshot = await FirebaseFirestore.instance
          .collection('crousal_images')
          .where('imageUrl', isEqualTo: imageUrl)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        imageUrls.remove(imageUrl);
      });

      _showSnackbar(
          widget.isSpanish
              ? '¡Imagen eliminada con éxito!'
              : 'Image deleted successfully!',
          Colors.green);
    } catch (e) {
      _showSnackbar(
          widget.isSpanish
              ? 'Error al eliminar la imagen: $e'
              : 'Error deleting image: $e',
          Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSpanish
        ? 'Actualizar Imágenes de Carrusel'
        : 'Update Crousal Images';
    final cameraText =
        widget.isSpanish ? 'Capturar con Cámara' : 'Capture with Camera';
    final galleryText =
        widget.isSpanish ? 'Seleccionar de Galería' : 'Select from Gallery';
    final clearText = widget.isSpanish ? 'Borrar Imagen' : 'Clear Image';
    final saveText = widget.isSpanish ? 'Guardar Imagen' : 'Save Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_selectedImage != null || _webImage != null)
                  Image.memory(
                    _webImage ?? _selectedImage!.readAsBytesSync(),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: Text(cameraText),
                      onPressed: () =>
                          _pickImage(source: ImageSource.camera), // Use camera
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: Text(galleryText),
                      onPressed: () => _pickImage(
                          source: ImageSource.gallery), // Use gallery
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedImage != null || _webImage != null)
                  ElevatedButton(
                    onPressed: _clearImage,
                    child: Text(clearText),
                  ),
                const SizedBox(height: 16),
                if (imageUrls.isNotEmpty)
                  CarouselSlider.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index, realIndex) {
                      final imageUrl = imageUrls[index];
                      return Stack(
                        children: [
                          Image.network(imageUrl, fit: BoxFit.cover),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteImage(imageUrl),
                            ),
                          ),
                        ],
                      );
                    },
                    options: CarouselOptions(
                      height: 250,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImage,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : Text(saveText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
