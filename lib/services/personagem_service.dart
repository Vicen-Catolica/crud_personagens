import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/personagem.dart';

class PersonagemService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _colecao => firestore
      .collection('usuarios')
      .doc(_uid)
      .collection('personagens');

  Future<void> criarHeroi(Personagem p) async {
    await _colecao.add(p.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listarPersonagens() {
    return _colecao.snapshots();
  }

  Future<void> tomarDano(String id, int novaVida) async {
    await _colecao.doc(id).update({'vida': novaVida});
  }

  Future<void> deletarPersonagem(String id) async {
    await _colecao.doc(id).delete();
  }
}