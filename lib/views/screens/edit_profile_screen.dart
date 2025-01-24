import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            var data = userDoc.data() as Map<String, dynamic>;
            _nameController.text = data['username'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _imageUrl = data['photoUrl'];
          });
        }
      } catch (e) {
        print("Error al obtener los datos: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        final storageRef =
            _storage.ref().child("profile_pics/${_user!.uid}.jpg");
        await storageRef.putFile(_imageFile!);
        String downloadUrl = await storageRef.getDownloadURL();
        setState(() {
          _imageUrl = downloadUrl;
        });
      } catch (e) {
        print("Error al subir la imagen: $e");
      }
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isSaving = true;
    });
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'username': _nameController.text,
        'lastName': _lastNameController.text,
        'bio': _bioController.text,
        'phone': _phoneController.text,
        'photoUrl': _imageUrl,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Información actualizada')));
    } catch (e) {
      print("Error al actualizar los datos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar los datos')));
    }
    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null
                                  ? NetworkImage(_imageUrl!)
                                  : const AssetImage(
                                          'assets/placeholder.png')
                                      as ImageProvider),
                        ),
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildProfileField("Nombre", _nameController),
                  const SizedBox(height: 15),
                  _buildProfileField("Apellido", _lastNameController),
                  const SizedBox(height: 15),
                  _buildProfileField("Biografía", _bioController),
                  const SizedBox(height: 15),
                  _buildProfileField("Teléfono", _phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      await _uploadImage();
                      await _updateUserData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Guardar cambios",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
