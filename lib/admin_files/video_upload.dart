import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // Import the file picker package
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/const.dart';

class UploadVideoScreen extends StatefulWidget {
  final bool isSpanish; // Added parameter to handle language

  const UploadVideoScreen({Key? key, required this.isSpanish})
      : super(key: key);

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  String? _editingVideoId;
  PlatformFile? _webImage; // For web image
  Uint8List? _webImageBytes;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker(); // Added ImagePicker instance

  // Texts in English and Spanish
  String get titleText => widget.isSpanish ? 'Título del video' : 'Video Title';
  String get linkText => widget.isSpanish ? 'Enlace del video' : 'Video Link';
  String get pickThumbnailText => widget.isSpanish
      ? 'Seleccionar imagen de miniatura'
      : 'Pick Thumbnail Image';
  String get uploadText => widget.isSpanish ? 'Subir video' : 'Upload Video';
  String get updateText =>
      widget.isSpanish ? 'Actualizar video' : 'Update Video';
  String get errorText => widget.isSpanish
      ? 'Por favor complete todos los campos y seleccione una imagen.'
      : 'Please fill all fields and select an image.';
  String get imageUploadError => widget.isSpanish
      ? 'Error al subir la imagen.'
      : 'Failed to upload image.';
  String get videoUploadedSuccess => widget.isSpanish
      ? '¡Video subido con éxito!'
      : 'Video uploaded successfully!';
  String get videoUpdatedSuccess => widget.isSpanish
      ? '¡Video actualizado con éxito!'
      : 'Video updated successfully!';
  String get videoDeletedSuccess => widget.isSpanish
      ? '¡Video eliminado con éxito!'
      : 'Video deleted successfully!';

  // Pick an image from the gallery or file picker (web support)
// For web (FilePicker)
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // For web
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        setState(() {
          _webImage = result.files.first;
          _webImageBytes = _webImage!.bytes; // Use bytes for uploading on web
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
      // For mobile/desktop (ImagePicker)
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  // Upload image to Firebase Storage and return the image URL
// Upload image to Firebase Storage (for both Web and Mobile)
  Future<String> _uploadImage() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName =
          'video_thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Uploading for Web (using bytes for web)
      if (kIsWeb && _webImageBytes != null) {
        final imageRef = storageRef.child(fileName);
        final uploadTask =
            imageRef.putData(_webImageBytes!); // Uploading as bytes for web
        await uploadTask;
        return await imageRef.getDownloadURL();
      }
      // Uploading for Mobile/Desktop (using File for mobile)
      else if (_selectedImage != null) {
        final imageRef = storageRef.child(fileName);
        final uploadTask =
            imageRef.putFile(_selectedImage!); // Uploading from File for mobile
        await uploadTask;
        return await imageRef.getDownloadURL();
      }
      return '';
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  // Save video data to Firestore
  Future<void> _saveVideoData(
      {required String title,
      required String link,
      required String imageUrl,
      required int sortOrder,
      String? videoId}) async {
    setState(() {
      _isUploading = true;
    });

    try {
      if (videoId == null) {
        // Add new video
        await _firestore.collection('videos').add({
          'title': title,
          'link': link,
          'imageUrl': imageUrl,
          'sort_order': sortOrder,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing video
        await _firestore.collection('videos').doc(videoId).update({
          'title': title,
          'link': link,
          'imageUrl': imageUrl,
          'sort_order': sortOrder,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              videoId == null ? videoUploadedSuccess : videoUpdatedSuccess),
        ),
      );
    } catch (e) {
      print("Error saving video data: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _editingVideoId = null;
        titleController.clear();
        linkController.clear();
        _sortOrderController.clear();
        _selectedImage = null;
      });
    }
  }

  // Delete video data
  Future<void> _deleteVideo(String videoId) async {
    setState(() {
      _isUploading = true;
    });
    try {
      await _firestore.collection('videos').doc(videoId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(videoDeletedSuccess)),
      );
    } catch (e) {
      print("Error deleting video: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _startEditing(DocumentSnapshot doc) {
    setState(() {
      _editingVideoId = doc.id;
      titleController.text = doc['title'];
      linkController.text = doc['link'];
      _sortOrderController.text = doc['sort_order'].toString();
      _selectedImage = null;
    });
  }

// Upload video and save data
  Future<void> _uploadVideo() async {
    if (titleController.text.isNotEmpty &&
        linkController.text.isNotEmpty &&
        _sortOrderController.text.isNotEmpty &&
        (_selectedImage != null ||
            _webImage != null ||
            _editingVideoId != null)) {
      final title = titleController.text;
      final link = linkController.text;
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

      String imageUrl = '';
      if (_selectedImage != null || _webImage != null) {
        imageUrl = await _uploadImage(); // Use the adjusted image upload method
      }

      if (_editingVideoId != null && imageUrl.isEmpty) {
        final doc =
            await _firestore.collection('videos').doc(_editingVideoId).get();
        imageUrl = doc['imageUrl'];
      }

      if (imageUrl.isNotEmpty) {
        await _saveVideoData(
          title: title,
          link: link,
          imageUrl: imageUrl,
          sortOrder: sortOrder,
          videoId: _editingVideoId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(imageUploadError)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSpanish ? 'Subir Video' : 'Upload Video',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.isSpanish ? 'Videos guardados' : 'Saved Videos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              // Stream for video data
              stream: _firestore.collection('videos').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final videos = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];

                    return ListTile(
                      leading: Image.network(video['imageUrl']),
                      title: Text(video['title']),
                      subtitle: Text(video['link']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _startEditing(video),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteVideo(video.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: titleText),
                  ),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(labelText: linkText),
                  ),
                  TextField(
                    controller: _sortOrderController,
                    decoration: InputDecoration(labelText: 'Sort Order'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  if (_selectedImage != null)
                    kIsWeb
                        ? Image.memory(
                            _webImageBytes!, // Use the bytes for web
                            height: 100,
                            width: 100,
                          )
                        : Image.file(
                            // Use File for mobile/desktop
                            _selectedImage!,
                            height: 100,
                            width: 100,
                          ),
                  // For mobile/desktop
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(pickThumbnailText),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading) const LinearProgressIndicator(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadVideo,
                    child:
                        Text(_editingVideoId == null ? uploadText : updateText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
