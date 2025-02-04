//Contact us screen called from drawer

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailsScreen extends StatelessWidget {
  final bool isSpanish;

  const ContactDetailsScreen({Key? key, required this.isSpanish})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? 'Contáctanos' : 'Contact Us',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 600, // Limit width for large screens
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Contact')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(isSpanish
                            ? 'No hay contactos disponibles.'
                            : 'No contacts available.'));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var doc in snapshot.data!.docs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ContactCard(
                            data: doc.data() as Map<String, dynamic>,
                            isSpanish: isSpanish,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSpanish;

  const ContactCard({Key? key, required this.data, required this.isSpanish})
      : super(key: key);

  void _handleTap(BuildContext context, String? value, String type) async {
    if (value == null || value.isEmpty) return;

    Uri uri;
    switch (type) {
      case 'phone':
        uri = Uri.parse('tel:$value');
        break;
      case 'whatsapp':
        uri = Uri.parse('https://wa.me/$value');
        break;
      case 'email':
        uri = Uri.parse('mailto:$value');
        break;
      case 'skype':
        uri = Uri.parse('skype:$value?call');
        break;
      case 'directions':
      case 'web':
        uri = Uri.parse(value);
        break;
      default:
        return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isSpanish
                ? 'No se pudo abrir el enlace $type'
                : 'Could not open $type link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContainer(
            context,
            Icons.phone,
            isSpanish ? 'Contacto' : 'Contact',
            data['contact_number'],
            'phone'),
        _buildContainer(
            context,
            Icons.contacts,
            isSpanish ? 'WhatsApp' : 'WhatsApp',
            data['whatsapp_number'],
            'whatsapp'),
        _buildContainer(context, Icons.email,
            isSpanish ? 'Correo electrónico' : 'Email', data['email'], 'email'),
        _buildContainer(context, Icons.video_call,
            isSpanish ? 'Skype' : 'Skype', data['skype'], 'skype'),
        _buildContainer(
            context,
            Icons.map,
            isSpanish ? 'Direcciones' : 'Directions',
            data['directions'],
            'directions'),
        _buildContainer(context, Icons.link,
            isSpanish ? 'Enlace web' : 'Web Link', data['web_link'], 'web'),
      ],
    );
  }

  Widget _buildContainer(BuildContext context, IconData icon, String label,
      String? value, String type) {
    String displayValue = value ?? (isSpanish ? 'N/A' : 'N/A');

    // If it's a web link, extract the base URL without the href
    if (type == 'web' && value != null) {
      Uri uri = Uri.parse(value);
      displayValue =
          uri.host; // This will show only the domain name (e.g., 'example.com')
    } else if (type == 'phone' && value != null) {
      displayValue = value.replaceAll(RegExp(r'\D'),
          ''); // Remove non-numeric characters from phone numbers
    } else if (type == 'whatsapp' && value != null) {
      displayValue = value.replaceAll(RegExp(r'\D'),
          ''); // Remove non-numeric characters from WhatsApp numbers
    }

    return GestureDetector(
      onTap: () => _handleTap(context, value, type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: $displayValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
