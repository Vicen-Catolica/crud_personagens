import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Aqui fica o Vigia: emite o usuário (ou null) sempre que a sessão muda
  Stream<User?> get estadoSessao => _auth.authStateChanges();

  User? get usuarioAtual => _auth.currentUser;

  // Chamada única que dispara o fluxo de login
  Future<void> entrar(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> cadastrar(String email, String senha) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    // Desafio Bônus 1: Criar documento de perfil em usuarios/{uid} no cadastro
    if (cred.user != null) {
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'email': email,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  // Lê o documento de perfil em usuarios/{uid} para exibir no cabeçalho
  Stream<DocumentSnapshot<Map<String, dynamic>>> obterPerfilUsuario() {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }

  Future<void> sair() => _auth.signOut();
}