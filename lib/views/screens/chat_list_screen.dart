import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Importar la pantalla de chat

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // Navegar a la pantalla de chat con otro usuario
  void _goToChat(String otherUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(otherUserId: otherUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verifica si el usuario está autenticado
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: _user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los chats'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes chats.'));
          }

          final chats = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index].data() as Map<String, dynamic>;
              List<dynamic> participants = chat['participants'] ?? [];
              String otherUserId = participants.firstWhere(
                  (participant) => participant != _user!.uid,
                  orElse: () => 'wsp3rgzusvcJqaIqzBovy4vIDxw2'); // Asigna este ID si no se encuentra otro usuario

              // Recupera el último mensaje (si existe)
              String lastMessage = chat['lastMessage'] ?? 'No hay mensajes';
              
              return ListTile(
                title: Text('Chat con $otherUserId'),
                subtitle: Text(lastMessage),
                onTap: () => _goToChat(otherUserId), // Ir a la pantalla de chat
              );
            },
          );
        },
      ),
    );
  }
}
