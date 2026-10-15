import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_inventario.dart';

class InventarioService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // UID do usuário logado
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Subcoleção de inventário dentro do documento do usuário logado: usuarios/{uid}/inventario
  CollectionReference<Map<String, dynamic>> get _colecao => firestore
      .collection('usuarios')
      .doc(_uid)
      .collection('inventario');

  Future<void> adicionarItem(ItemInventario item) async {
    await _colecao.add(item.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listarItens() {
    return _colecao.snapshots();
  }

  Future<void> removerItem(String id) async {
    await _colecao.doc(id).delete();
  }
}
