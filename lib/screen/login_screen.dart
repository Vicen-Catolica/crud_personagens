import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _modoCadastro = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text;

      if (_modoCadastro) {
        await _auth.cadastrar(email, senha);
      } else {
        await _auth.entrar(email, senha);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const ouro = Color(0xFFD4A94A);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.castle, size: 72, color: ouro),
                const SizedBox(height: 8),
                const Text(
                  "THE DEV'S QUEST",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: ouro,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email, color: ouro),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.vpn_key, color: ouro),
                  ),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E1E),
                      foregroundColor: const Color(0xFFEADBB8),
                    ),
                    child: _carregando
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_modoCadastro ? 'CRIAR CONTA' : 'ENTRAR'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _modoCadastro = !_modoCadastro;
                    _erro = null;
                  }),
                  child: Text(
                    _modoCadastro
                        ? 'Já tenho conta. Entrar'
                        : 'Novo aventureiro? Criar conta',
                    style: const TextStyle(color: ouro),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}