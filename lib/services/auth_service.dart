import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get estadoSessao => _auth.authStateChanges();

  User? get usuarioAtual => _auth.currentUser;

  Future<void> entrar(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> cadastrar(String email, String senha) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    if (cred.user != null) {
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'email': email,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> obterPerfilUsuario() {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }

  Future<void> sair() => _auth.signOut();
}