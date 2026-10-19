import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': _emailCtrl.text.trim(),
        'pass': _passCtrl.text,
      });
      
      final token = response.data['access_token'];
      final user = User.fromJson(response.data['user']);
      
      await ref.read(authProvider.notifier).setUser(user, token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión. Intenta de nuevo.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF475569),
              ),
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, size: 80, color: Color(0xFF6366F1)),
                        const SizedBox(height: 16),
                        Text(
                          'Aprende Estudia',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 40),
                    TextField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscureText,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF94A3B8)),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                            : const Text('Ingresar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
