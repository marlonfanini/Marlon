import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? _user;
  TextEditingController _controller = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // Enviar el mensaje (con o sin imagen)
  Future<void> _sendMessage() async {
    if (_user == null || (_controller.text.isEmpty && _image == null)) return;

    try {
      // Verifica si ya existe un chat con este usuario
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _user!.uid)
          .where('participants', arrayContains: widget.otherUserId)
          .get();

      DocumentReference chatRef;

      if (chatSnapshot.docs.isEmpty) {
        // Si no existe, crea uno nuevo
        chatRef = await _firestore.collection('chats').add({
          'participants': [_user!.uid, widget.otherUserId],
          'lastMessage': _controller.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Si ya existe, toma el chat existente
        chatRef = chatSnapshot.docs.first.reference;
      }

      // Agregar mensaje al chat
      await chatRef.collection('messages').add({
        'senderId': _user!.uid,
        'receiverId': widget.otherUserId,
        'message': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
        'image': _image != null ? await _uploadImage(_image!) : null,
      });

      // Limpiar campos
      _controller.clear();
      setState(() {
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado')),
      );
    } catch (e) {
      print("Error al enviar mensaje: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar mensaje')),
      );
    }
  }

  // Subir la imagen a Firebase Storage
  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = _storage.ref().child('chat_images/${DateTime.now().toString()}');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error al subir la imagen: $e");
      return '';
    }
  }

  // Seleccionar imagen de la galería
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.otherUserId}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: _user!.uid)
                  .where('participants', arrayContains: widget.otherUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los mensajes'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay mensajes.'));
                }

                final chatDoc = snapshot.data!.docs.first;
                final chatId = chatDoc.id; // ID del chat
                final messagesStream = _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots();

                return StreamBuilder<QuerySnapshot>(
                  stream: messagesStream,
                  builder: (context, messagesSnapshot) {
                    if (messagesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (messagesSnapshot.hasError) {
                      return const Center(child: Text('Error al cargar los mensajes'));
                    }

                    final messages = messagesSnapshot.data?.docs ?? [];
                    return ListView.builder(
                      reverse: true, // Mostrar los mensajes más recientes al principio
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(message['message'] ?? ''),
                          subtitle: message['image'] != null
                              ? Image.network(message['image'])
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
