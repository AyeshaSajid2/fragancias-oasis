import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:oasis_fragrances/utils/send_notification.dart';

class SendNotificationScreen extends StatefulWidget {
  final bool isSpanish;

  const SendNotificationScreen({Key? key, required this.isSpanish})
      : super(key: key);

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('notification_images/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "Error al cargar la imagen"
              : "Error uploading image"),
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    String title = titleController.text.trim();
    String body = bodyController.text.trim();
    String link = linkController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSpanish
              ? "Por favor ingrese título y mensaje"
              : "Please enter title and message"),
        ),
      );
      return;
    }

    // Upload image if selected
    final imageUrl = await _uploadImage();

    // Save notification data in Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'image': imageUrl ?? '', // Default to empty string if no image
      'link': link.isNotEmpty ? link : '', // Default to empty string if no link
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send push notification
    sendNotificationToAllUsers(
      title,
      body,
      imageUrl ?? '', // Default to empty string if no image
      link.isNotEmpty ? link : '', // Default to empty string if no link
    );

    // Success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isSpanish
            ? "¡Notificación enviada con éxito!"
            : "Notification sent successfully!"),
      ),
    );

    // Clear inputs
    titleController.clear();
    bodyController.clear();
    linkController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    String titleLabel =
        widget.isSpanish ? 'Título de notificación' : 'Notification Title';
    String bodyLabel =
        widget.isSpanish ? 'Mensaje de notificación' : 'Notification Message';
    String linkLabel =
        widget.isSpanish ? 'Enlace de notificación' : 'Notification Link';
    String buttonLabel =
        widget.isSpanish ? 'Enviar notificación' : 'Send Notification';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSpanish ? 'Enviar Notificación' : 'Send Notification',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white), // Set the icon color
        backgroundColor:
            AppTheme.secondaryColor, // Set the app bar background color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notification Title TextField
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: titleLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Notification Message TextField
              TextField(
                controller: bodyController,
                decoration: InputDecoration(
                  labelText: bodyLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                maxLines: 4,
              ),
              SizedBox(height: 16.0),

              // Notification Link TextField
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: linkLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Image Picker
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(widget.isSpanish
                        ? 'Seleccionar Imagen'
                        : 'Select Image'),
                  ),
                  SizedBox(width: 16.0),
                  if (_selectedImage != null)
                    Text(
                      widget.isSpanish
                          ? 'Imagen Seleccionada'
                          : 'Image Selected',
                      style: TextStyle(color: Colors.green),
                    ),
                ],
              ),
              SizedBox(height: 16.0),

              // Send Notification Button
              ElevatedButton(
                onPressed: _isUploading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(buttonLabel, style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
