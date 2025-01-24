import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Método de registro de usuario
  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    required String lastName,
    required String phone,
  }) async {
    try {
      // Crear usuario con FirebaseAuth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar que el usuario ha sido creado correctamente
      if (userCredential.user == null) {
        throw Exception('Error al crear el usuario. Usuario no encontrado.');
      }

      // Obtener UID del usuario
      String uid = userCredential.user!.uid;

      // Guardar datos adicionales en Firestore
      await _firebaseFirestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'lastName': lastName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'bio': '', // Campo de biografía vacío por defecto
        'photoUrl': '', // URL de foto vacía por defecto
      });

      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Cuenta creada con éxito!",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      // Mostrar mensaje de error con detalles
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Fluttertoast.showToast(
        msg: "Sesión cerrada con éxito.",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      // En caso de error al cerrar sesión
      Fluttertoast.showToast(
        msg: "Error al cerrar sesión: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
}
