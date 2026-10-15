import 'package:cloud_firestore/cloud_firestore.dart';

class Missao {
  String? id;
  String titulo;
  DateTime concluidaEm;

  Missao({
    this.id,
    required this.titulo,
    required this.concluidaEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'concluidaEm': Timestamp.fromDate(concluidaEm),
    };
  }

  factory Missao.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawData = map['concluidaEm'];
    DateTime dataConcluida;
    if (rawData is Timestamp) {
      dataConcluida = rawData.toDate();
    } else if (rawData is String) {
      dataConcluida = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      dataConcluida = DateTime.now();
    }

    return Missao(
      id: id,
      titulo: map['titulo'] ?? '',
      concluidaEm: dataConcluida,
    );
  }
}
