class ItemInventario {
  String? id;
  String nome;
  int quantidade;

  ItemInventario({
    this.id,
    required this.nome,
    required this.quantidade,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'quantidade': quantidade,
    };
  }

  factory ItemInventario.fromMap(Map<String, dynamic> map, {String? id}) {
    return ItemInventario(
      id: id,
      nome: map['nome'] ?? '',
      quantidade: (map['quantidade'] ?? 1) as int,
    );
  }
}
