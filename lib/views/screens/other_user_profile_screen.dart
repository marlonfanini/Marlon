import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _otherUserData;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _getOtherUserData();
    }
  }

  Future<void> _getOtherUserData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          _otherUserData = userDoc.data() as Map<String, dynamic>;
        });
        _checkIfFollowing();
      } else {
        setState(() {
          _otherUserData = {};
        });
        print("El documento del otro usuario no existe.");
      }
    } catch (e) {
      print("Error al obtener los datos del otro usuario: $e");
    }
  }

  void _checkIfFollowing() {
    if (_user != null && _otherUserData != null) {
      setState(() {
        isFollowing = _otherUserData!['followers']?.contains(_user!.uid) ?? false;
      });
    }
  }

  Future<void> _followUser(String followedUserId) async {
    try {
      final userDoc = _firestore.collection('users').doc(_user!.uid);
      final followedUserDoc = _firestore.collection('users').doc(followedUserId);

      await userDoc.update({
        'following': FieldValue.arrayUnion([followedUserId])
      });
      await followedUserDoc.update({
        'followers': FieldValue.arrayUnion([_user!.uid])
      });

      _getOtherUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario seguido correctamente')),
      );
    } catch (e) {
      print("Error al seguir usuario: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al seguir usuario')),
      );
    }
  }

  Future<void> _unfollowUser() async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'followers': FieldValue.arrayRemove([_user!.uid]),
      });
      await _firestore.collection('users').doc(_user!.uid).update({
        'following': FieldValue.arrayRemove([widget.userId]),
      });

      setState(() {
        isFollowing = false;
      });
    } catch (e) {
      print("Error al dejar de seguir al usuario: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_otherUserData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Perfil de Usuario"),
          backgroundColor: Colors.blueAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _otherUserData?['photoUrl'] != null
                      ? NetworkImage(_otherUserData!['photoUrl'])
                      : const AssetImage('assets/placeholder.png')
                          as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _otherUserData?['username'] ?? 'Cargando...',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _otherUserData?['email'] ?? 'Cargando...',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Biografía",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _otherUserData?['bio'] ?? 'Sin biografía',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isFollowing
                    ? _unfollowUser
                    : () => _followUser(widget.userId),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: isFollowing ? Colors.redAccent : Colors.blueAccent,
                ),
                child: Text(
                  isFollowing ? "Dejar de Seguir" : "Seguir",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
