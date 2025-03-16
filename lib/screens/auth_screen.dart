import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text;
    final password = _passwordController.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLogin) {
        await auth.signIn(email, password);
      } else {
        await auth.signUp(email, password);
      }
      Navigator.pushReplacementNamed(context, '/transactions');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na autenticação: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) => value!.contains('@') ? null : 'Email inválido',
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator:
                    (value) =>
                        value!.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Entrar' : 'Cadastrar'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Criar nova conta' : 'Já possui conta? Entrar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
