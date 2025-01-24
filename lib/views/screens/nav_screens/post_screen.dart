import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Para trabajar con archivos locales
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _file; // Imagen o video seleccionado
  String? _mediaUrl; // URL de la imagen/video subida
  String _description = ''; // Descripción del post

  // Método para seleccionar imagen o video
  Future<void> _pickMedia() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    ); // Usamos pickImage para solo imágenes

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  // Método para subir la imagen o video a Firebase Storage
  Future<void> _uploadMedia() async {
    if (_file != null) {
      try {
        // Subir a Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('posts')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = ref.putFile(_file!);

        // Esperamos a que termine la carga
        final snapshot = await uploadTask.whenComplete(() {});

        // Obtener la URL de la imagen o video subida
        final mediaUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _mediaUrl = mediaUrl;
        });
      } catch (e) {
        print("Error al subir el archivo: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la publicación')),
        );
        return;
      }
    }

    // Guardar la publicación en Firestore, incluso si no hay archivo multimedia
    _savePostToFirestore();
  }

 // Método para guardar la publicación en Firestore
Future<void> _savePostToFirestore() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user is logged in');
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc();

    await postRef.set({
      'userId': user.uid,
      'mediaUrl': _mediaUrl, // Puede ser null si no se sube imagen o video
      'description': _description,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [], // Campo likes vacío
      'comments': [],
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicación creada')),
    );

    // Limpiar campos después de la publicación
    setState(() {
      _file = null;
      _description = '';
    });
  } catch (e) {
    print("Error al guardar la publicación: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al guardar la publicación')),
    );
  }
} 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickMedia,
              child: const Text('Seleccionar Imagen/Video'),
            ),
            const SizedBox(height: 16.0),
            _file != null
                ? Image.file(
                    _file!) // Muestra la vista previa de la imagen o video
                : const Text('No se ha seleccionado ningún archivo.'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadMedia,
              child: const Text('Subir Publicación'),
            ),
          ],
        ),
      ),
    );
  }
}
