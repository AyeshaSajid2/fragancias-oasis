///list existing admins
///delete admin
///register new admin navigation
///saving to firebase
//

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/auth/admin_auth/admin_registerr_screen.dart';
import 'package:oasis_fragrances/utils/const.dart';

class AdminListScreen extends StatefulWidget {
  final Function(String) setLocale;
  final bool isSpanish; // Added isSpanish parameter

  const AdminListScreen(
      {Key? key, required this.setLocale, this.isSpanish = false})
      : super(key: key);

  @override
  _AdminListScreenState createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Localization map for English and Spanish
  late Map<String, String> localizedText;

  @override
  void initState() {
    super.initState();
    _setLocalizedText();
  }

  void _setLocalizedText() {
    localizedText = widget.isSpanish
        ? {
            'adminList': 'Lista de Administradores',
            'noAdmins': 'No se encontraron administradores.',
            'deleteAdmin': 'Eliminar Administrador',
            'enterPassword':
                'Ingrese la contraseña del administrador a eliminar:',
            'passwordHint': 'Contraseña',
            'cancel': 'Cancelar',
            'delete': 'Eliminar',
            'adminDeleted': 'Administrador eliminado con éxito.',
            'registerNewAdmin': 'Registrar Nuevo Administrador',
          }
        : {
            'adminList': 'Admin List',
            'noAdmins': 'No admins found.',
            'deleteAdmin': 'Delete Admin',
            'enterPassword': 'Enter the password of the admin to delete:',
            'passwordHint': 'Password',
            'cancel': 'Cancel',
            'delete': 'Delete',
            'adminDeleted': 'Admin deleted successfully.',
            'registerNewAdmin': 'Register New Admin',
          };
  }

  Future<void> _deleteAdmin(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        var adminDoc = await _firestore
            .collection('admins')
            .where('adminEmail', isEqualTo: email)
            .get();

        if (adminDoc.docs.isNotEmpty) {
          for (var doc in adminDoc.docs) {
            await doc.reference.delete();
          }

          await userCredential.user!.delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedText['adminDeleted']!)),
          );
        } else {
          throw 'Admin not found in Firestore';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRegisterScreen(
          setLocale: widget.setLocale,
          language: widget.isSpanish
              ? "spanish"
              : "English", // Pass "Spanish" or "English"
        ),
      ),
    );
  }

  void _showDeleteDialog(String email) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizedText['deleteAdmin']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizedText['enterPassword']!),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration:
                    InputDecoration(hintText: localizedText['passwordHint']),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(localizedText['cancel']!),
            ),
            ElevatedButton(
              onPressed: () {
                String password = passwordController.text.trim();
                Navigator.pop(context);
                _deleteAdmin(email, password);
              },
              child: Text(localizedText['delete']!),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryColor,
        title: Text(
          localizedText['adminList']!,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('admins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(localizedText['noAdmins']!));
          }

          final adminDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 3 / 2,
            ),
            itemCount: adminDocs.length,
            itemBuilder: (context, index) {
              final adminData = adminDocs[index].data() as Map<String, dynamic>;
              final email = adminData['adminEmail'] ?? 'Unknown';
              final name = adminData['adminName'] ?? 'Unknown';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () => _showDeleteDialog(email),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        localizedText['delete']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _navigateToRegisterScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            localizedText['registerNewAdmin']!,
            style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
    );
  }
}
