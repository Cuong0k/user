import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    final pw = _pw.text;
    if (email.isEmpty || pw.isEmpty) return _toast('Vui lòng nhập email và mật khẩu');

    final ok = await auth.login(email, pw);
    if (!mounted) return;
    if (!ok) _toast(auth.error ?? 'Đăng nhập thất bại');
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryGlow],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome back',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('Global high-speed network',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Enter email address'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pw,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Enter password'),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
