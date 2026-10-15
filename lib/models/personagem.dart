class Personagem {
  String? id;
  String? nome;
  int? vida;
  int? forca;

  Personagem({
    this.id,
    required this.nome,
    required this.vida,
    required this.forca,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'vida': vida,
      'forca': forca,
    };
  }

  factory Personagem.fromMap(Map<String, dynamic> map, {String? id}) {
    return Personagem(
      id: id,
      nome: map['nome'] ?? '',
      vida: (map['vida'] ?? 0) as int,
      forca: (map['forca'] ?? 0) as int,
    );
  }
}