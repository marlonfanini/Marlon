import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<List<DocumentSnapshot>> _getPosts() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print("Error al obtener las publicaciones: $e");
      return [];
    }
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      if (isLiked) {
        await postRef.update({'likes': FieldValue.arrayRemove([user.uid])});
      } else {
        await postRef.update({'likes': FieldValue.arrayUnion([user.uid])});
      }
    } catch (e) {
      print("Error al actualizar el like: $e");
    }
  }

  Future<void> _addComment(String postId, String comment) async {
    if (comment.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      await postRef.update({
        'comments': FieldValue.arrayUnion([
          {
            'userId': user.uid,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
          },
        ]),
      });
    } catch (e) {
      print("Error al agregar comentario: $e");
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print("Error al obtener los datos del usuario: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay publicaciones.'));
          }

          List<DocumentSnapshot> posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index];
              String postId = post.id;
              String description = post['description'];
              String mediaUrl = post['mediaUrl'] ?? '';
              Timestamp timestamp = post['timestamp'];
              List<dynamic> likes = post['likes'] ?? [];
              List<dynamic> comments = post['comments'] ?? [];
              bool isLiked =
                  likes.contains(FirebaseAuth.instance.currentUser?.uid);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://via.placeholder.com/150",
                        ),
                      ),
                      title: FutureBuilder<Map<String, dynamic>>(
                        future: _getUserData(post['userId']),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Cargando...');
                          }
                          if (!userSnapshot.hasData) {
                            return const Text('Usuario desconocido');
                          }
                          return Text(userSnapshot.data!['username'] ?? 'Usuario');
                        },
                      ),
                      subtitle: Text(
                        timestamp.toDate().toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (mediaUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(mediaUrl),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null,
                          ),
                          onPressed: () => _toggleLike(postId, isLiked),
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                TextEditingController commentController =
                                    TextEditingController();
                                return AlertDialog(
                                  title: const Text('Agregar Comentario'),
                                  content: TextField(
                                    controller: commentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Escribe tu comentario',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _addComment(
                                            postId, commentController.text);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Enviar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    if (comments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Text(
                              'Comentarios:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            for (var comment in comments)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: FutureBuilder<Map<String, dynamic>>(
                                  future: _getUserData(comment['userId']),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    if (!userSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            userSnapshot.data![
                                                    'profileImageUrl'] ??
                                                "https://via.placeholder.com/150",
                                          ),
                                          radius: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              text:
                                                  "${userSnapshot.data!['username']}: ",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              children: [
                                                TextSpan(
                                                  text: comment['comment'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
