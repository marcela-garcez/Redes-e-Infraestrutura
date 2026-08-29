import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../models/user.dart';
import '../services/user_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool _showPassword = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    return value == null || value.trim().isEmpty ? 'Informe $field' : null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, 'seu e-mail');
    if (required != null) return required;
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return isEmail ? null : 'Digite um e-mail válido';
  }

  String? _validatePhone(String? value) {
    final required = _required(value, 'seu telefone');
    if (required != null) return required;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 ? null : 'Digite um telefone válido';
  }

  String? _validatePassword(String? value) {
    final required = _required(value, 'sua senha');
    if (required != null) return required;
    return value!.length < 6 ? 'A senha deve ter ao menos 6 caracteres' : null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final firebaseUser = credential.user!;
      await UserRepository().createUser(UserModel(
        uid: firebaseUser.uid,
        name: _nameController.text,
        phone: _phoneController.text,
        email: firebaseUser.email ?? _emailController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim());
    } on FirebaseAuthException catch (error) {
      _showError(error.code == 'email-already-in-use'
          ? 'Este e-mail já está cadastrado.'
          : error.message ?? 'Não foi possível concluir o cadastro.');
    } catch (_) {
      _showError('Não foi possível salvar seus dados. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Crie sua conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Preencha os dados abaixo para finalizar seu cadastro.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5B6570))),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => _required(value, 'seu nome'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [_phoneMask],
                      decoration: const InputDecoration(labelText: 'Telefone', hintText: '(00) 00000-0000', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail', hintText: 'voce@empresa.com', prefixIcon: Icon(Icons.email_outlined)),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _register,
                        child: _isSubmitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('CADASTRAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
