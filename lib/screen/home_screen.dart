import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud/services/personagem_service.dart';
import 'package:flutter/material.dart';

import '../models/item_inventario.dart';
import '../models/missao.dart';
import '../models/personagem.dart';
import '../services/auth_service.dart';
import '../services/inventario_service.dart';
import '../services/missao_service.dart';

const _fundo = Color(0xFF14100C);
const _pergaminho = Color(0xFF241B13);
const _borda = Color(0xFF5A452A);
const _ouro = Color(0xFFD4A94A);
const _textoClaro = Color(0xFFEADBB8);
const _vidaMax = 100;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //chamada do serviço de autenticação
  final _auth = AuthService();

  final PersonagemService _service = PersonagemService();
  final MissaoService _missaoService = MissaoService();
  final InventarioService _inventarioService = InventarioService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _vidaController = TextEditingController();
  final TextEditingController _forcaController = TextEditingController();
  final TextEditingController _missaoTituloController = TextEditingController();
  final TextEditingController _itemNomeController = TextEditingController();
  final TextEditingController _itemQtdController = TextEditingController();

  int _abaSelecionada = 0; // 0 = Heróis, 1 = Missões, 2 = Inventário

  @override
  void dispose() {
    _nomeController.dispose();
    _vidaController.dispose();
    _forcaController.dispose();
    _missaoTituloController.dispose();
    _itemNomeController.dispose();
    _itemQtdController.dispose();
    super.dispose();
  }

  Future<void> _criarHeroi() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final heroi = Personagem(
      nome: nome,
      vida: int.tryParse(_vidaController.text) ?? 100,
      forca: int.tryParse(_forcaController.text) ?? 50,
    );

    await _service.criarHeroi(heroi);
    _nomeController.clear();
  }

  Future<void> _concluirMissao() async {
    final titulo = _missaoTituloController.text.trim();
    if (titulo.isEmpty) return;

    await _missaoService.concluirMissao(titulo);
    _missaoTituloController.clear();
  }

  Future<void> _adicionarItemInventario() async {
    final nome = _itemNomeController.text.trim();
    if (nome.isEmpty) return;

    final item = ItemInventario(
      nome: nome,
      quantidade: int.tryParse(_itemQtdController.text) ?? 1,
    );

    await _inventarioService.adicionarItem(item);
    _itemNomeController.clear();
    _itemQtdController.clear();
  }

  Future<void> _atacar(Personagem p) async {
    final novaVida = (p.vida! - 20).clamp(0, 9999);
    await _service.tomarDano(p.id!, novaVida);
  }

  Future<void> _curar(Personagem p) =>
      _service.tomarDano(p.id!, (p.vida! + 20).clamp(0, _vidaMax));

  String _formatarDataHora(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final ano = dt.year;
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$min';
  }

  // Escolhe o ícone do herói pela "classe" digitada no nome
  IconData _iconeDe(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('mago') || n.contains('bruxo')) return Icons.auto_fix_high;
    if (n.contains('ladino') || n.contains('assassino')) {
      return Icons.visibility_off;
    }
    if (n.contains('arqueiro') || n.contains('cacador')) {
      return Icons.gps_fixed;
    }
    if (n.contains('guerreiro') || n.contains('cavaleiro')) {
      return Icons.shield;
    }
    return Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1D12), _fundo],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _cabecalho(),
              _seletorAbas(),
              if (_abaSelecionada == 0) ...[
                _formulario(),
                _tituloSecao('⚔  LISTA DE HERÓIS  ⚔'),
                Expanded(child: _listaHerois()),
              ] else if (_abaSelecionada == 1) ...[
                _formularioMissao(),
                _tituloSecao('📜  MISSÕES CONCLUÍDAS  📜'),
                Expanded(child: _listaMissoes()),
              ] else ...[
                _formularioInventario(),
                _tituloSecao('🎒  INVENTÁRIO DO AVENTUREIRO  🎒'),
                Expanded(child: _listaInventario()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              const Text(
                "THE DEV'S QUEST",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: _ouro,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
              // Desafio Bônus 1: Lê e exibe os dados de perfil de usuarios/{uid}
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _auth.obterPerfilUsuario(),
                builder: (context, snapshot) {
                  final dados = snapshot.data?.data();
                  final email =
                      dados?['email'] as String? ?? _auth.usuarioAtual?.email ?? '';
                  final criadoEmTs = dados?['criadoEm'];
                  String subtitulo = email;
                  if (criadoEmTs is Timestamp) {
                    final dt = criadoEmTs.toDate();
                    final dia = dt.day.toString().padLeft(2, '0');
                    final mes = dt.month.toString().padLeft(2, '0');
                    final ano = dt.year;
                    subtitulo = '$email • Desde $dia/$mes/$ano';
                  }
                  // Aqui mostra quem está logado
                  return Text(
                    subtitulo,
                    style: const TextStyle(color: _textoClaro, fontSize: 12),
                  );
                },
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    _ouro,
                    Colors.transparent,
                  ]),
                ),
              ),
            ],
          ),
          // Botão para logout. O AuthGate leva de volta ao Login sozinho
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              tooltip: 'Sair',
              onPressed: _auth.sair,
              icon: const Icon(Icons.logout, color: _ouro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seletorAbas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          _botaoAba(0, Icons.shield, 'HERÓIS'),
          const SizedBox(width: 8),
          _botaoAba(1, Icons.menu_book, 'MISSÕES'),
          const SizedBox(width: 8),
          _botaoAba(2, Icons.backpack, 'INVENTÁRIO'),
        ],
      ),
    );
  }

  Widget _botaoAba(int index, IconData icone, String rotulo) {
    final ativo = _abaSelecionada == index;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _abaSelecionada = index),
        icon: Icon(icone, size: 16, color: ativo ? _fundo : _ouro),
        label: Text(
          rotulo,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ativo ? _fundo : _textoClaro,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: ativo ? _ouro : _pergaminho,
          side: BorderSide(color: ativo ? _ouro : _borda, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        texto,
        style: const TextStyle(
          color: _ouro,
          letterSpacing: 2,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _formulario() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pergaminho,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borda, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _nomeController,
            style: const TextStyle(color: _textoClaro),
            decoration: const InputDecoration(
              labelText: 'Nome do herói (ex: Mago Gandalf)',
              prefixIcon: Icon(Icons.badge, color: _ouro),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vidaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _textoClaro),
                  decoration: const InputDecoration(
                    labelText: 'Vida',
                    prefixIcon: Icon(Icons.favorite, color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _forcaController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _textoClaro),
                  decoration: const InputDecoration(
                    labelText: 'Força',
                    prefixIcon: Icon(Icons.fitness_center, color: _ouro),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _criarHeroi,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'INVOCAR HERÓI',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: _textoClaro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _ouro, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaHerois() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.listarPersonagens(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _ouro));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'A coleção aguarda seu primeiro herói...',
              style: TextStyle(
                  color: _borda, fontStyle: FontStyle.italic, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final p = Personagem.fromMap(doc.data(), id: doc.id);
            return _cardHeroi(p);
          },
        );
      },
    );
  }

  Widget _cardHeroi(Personagem p) {
    final morto = p.vida! <= 0;
    final pct = (p.vida! / _vidaMax).clamp(0.0, 1.0);

    // Verde -> amarelo -> vermelho conforme a vida
    final corVida = pct > 0.6
        ? const Color(0xFF4CAF50)
        : pct > 0.3
        ? const Color(0xFFFFB300)
        : const Color(0xFFD32F2F);

    return Opacity(
      opacity: morto ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _pergaminho,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: morto ? Colors.grey : _borda, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1C150F),
                    border: Border.all(color: _ouro, width: 2),
                  ),
                  child: Icon(
                    morto ? Icons.heart_broken : _iconeDe(p.nome!),
                    color: morto ? Colors.grey : _ouro,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nome!,
                        style: const TextStyle(
                          color: _textoClaro,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.fitness_center,
                              size: 14, color: _ouro),
                          const SizedBox(width: 4),
                          Text('STR ${p.forca}',
                              style: const TextStyle(color: _ouro)),
                          if (morto) ...[
                            const SizedBox(width: 10),
                            const Text('☠ CAÍDO',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de vida estilo RPG
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _borda),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pct == 0 ? 0.001 : pct,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          colors: [corVida, corVida.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'HP ${p.vida} / $_vidaMax',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: morto ? null : () => _atacar(p),
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('DANO -20'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                          color: morto ? Colors.grey : Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _curar(p),
                    icon: const Icon(Icons.healing, size: 18),
                    label: const Text('CURAR +20'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF66BB6A),
                      side: const BorderSide(color: Color(0xFF66BB6A)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Matar personagem',
                  onPressed: () => _service.deletarPersonagem(p.id!),
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Parte 3: Formulário e listagem da subcoleção usuarios/{uid}/missoes
  Widget _formularioMissao() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pergaminho,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borda, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _missaoTituloController,
            style: const TextStyle(color: _textoClaro),
            decoration: const InputDecoration(
              labelText: 'Título da missão (ex: Derrotar o Dragão de Fogo)',
              prefixIcon: Icon(Icons.flag, color: _ouro),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _concluirMissao,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'CONCLUIR MISSÃO',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: _textoClaro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _ouro, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaMissoes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _missaoService.listarMissoes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _ouro));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma missão concluída ainda...',
              style: TextStyle(
                  color: _borda, fontStyle: FontStyle.italic, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final m = Missao.fromMap(doc.data(), id: doc.id);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pergaminho,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borda, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 6)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: _ouro, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.titulo,
                          style: const TextStyle(
                            color: _textoClaro,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Concluída em: ${_formatarDataHora(m.concluidaEm)}',
                          style: const TextStyle(color: _ouro, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir missão',
                    onPressed: () => _missaoService.deletarMissao(m.id!),
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Desafio Bônus 2: Subcoleção usuarios/{uid}/inventario protegida pela mesma regra recursiva
  Widget _formularioInventario() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pergaminho,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borda, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemNomeController,
                  style: const TextStyle(color: _textoClaro),
                  decoration: const InputDecoration(
                    labelText: 'Item (ex: Poção de Mana)',
                    prefixIcon: Icon(Icons.science, color: _ouro),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _itemQtdController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _textoClaro),
                  decoration: const InputDecoration(
                    labelText: 'Qtd',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _adicionarItemInventario,
              icon: const Icon(Icons.add_box),
              label: const Text(
                'GUARDAR NO INVENTÁRIO',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: _textoClaro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _ouro, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaInventario() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _inventarioService.listarItens(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _ouro));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Sua mochila está vazia...',
              style: TextStyle(
                  color: _borda, fontStyle: FontStyle.italic, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final item = ItemInventario.fromMap(doc.data(), id: doc.id);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pergaminho,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borda, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 6)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: _ouro, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${item.nome} (x${item.quantidade})',
                      style: const TextStyle(
                        color: _textoClaro,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Descartar item',
                    onPressed: () => _inventarioService.removerItem(item.id!),
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}