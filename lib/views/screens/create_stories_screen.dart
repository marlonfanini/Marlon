import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importar Firebase Storage
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  _CreateStoryScreenState createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _image; // Variable para almacenar la imagen seleccionada

  // Función para seleccionar imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  // Función para subir la imagen a Firebase Storage
  Future<String?> _uploadImage() async {
    try {
      final File file = File(_image!.path);
      final storageRef = FirebaseStorage.instance.ref().child('stories/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(file);
      await uploadTask;

      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error al subir imagen: $e");
      return null;
    }
  }

  // Función para crear y guardar la historia en Firebase
  Future<void> _createStory() async {
    String description = _descriptionController.text;

    if (description.isEmpty) {
      return; // Asegúrate de que haya contenido para publicar
    }

    try {
      String? imageUrl;

      // Si hay una imagen seleccionada, la subimos y obtenemos la URL
      if (_image != null) {
        imageUrl = await _uploadImage(); // Subir imagen a Firebase Storage
        if (imageUrl == null) return; // Si no se sube la imagen, no publicamos
      }

      // Guardar la historia en Firestore (con o sin imagen)
      await _firestore.collection('stories').add({
        'description': description,
        'imageUrl': imageUrl ?? '', // Si no hay imagen, se guarda un string vacío
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      });

      // Mostrar un Snackbar indicando que la historia fue publicada correctamente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Historia publicada correctamente")),
      );

      // Volver a la pantalla principal
      Navigator.pop(context);
    } catch (e) {
      print("Error al crear historia: $e");

      // Mostrar un Snackbar en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al publicar la historia")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Historia")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Escribe algo sobre tu historia...",
              ),
            ),
            const SizedBox(height: 10),
            _image == null
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Seleccionar Imagen"),
                  )
                : Image.file(
                    File(_image!.path),
                    height: 200,
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createStory,
              child: const Text("Publicar Historia"),
            ),
          ],
        ),
      ),
    );
  }
}
