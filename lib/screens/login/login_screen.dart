import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/v2board_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _code = TextEditingController();
  final _invite = TextEditingController();
  int _countdown = 0;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _code.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.isEmpty) return _toast('Please enter email address');
    try {
      await V2BoardService.instance.sendEmailCode(_email.text.trim());
      setState(() => _countdown = 60);
      _tick();
      _toast('Code sent');
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
        _tick();
      }
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();
    final pw = _pw.text;
    if (email.isEmpty || pw.isEmpty) return _toast('Please enter email and password');
    if (pw.length < 6) return _toast('Password must be at least 6 characters');

    final ok = _isRegister
        ? await auth.register(email, pw, _code.text.trim(),
            _invite.text.trim().isEmpty ? null : _invite.text.trim())
        : await auth.login(email, pw);

    if (!mounted) return;
    if (!ok) _toast(auth.error ?? 'Failed');
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
              Text(
                _isRegister ? 'Register Account' : 'Welcome back',
                style: const TextStyle(
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
              if (_isRegister) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _code,
                        decoration:
                            const InputDecoration(hintText: 'Verification code'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _countdown > 0 ? null : _sendCode,
                        child: Text(_countdown > 0 ? '${_countdown}s' : 'Send'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _invite,
                  decoration: const InputDecoration(
                      hintText: 'Enter invite code (optional)'),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isRegister ? 'Register' : 'Log in'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? 'Already have an account? Log in'
                      : "Don't have an account? Register Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
