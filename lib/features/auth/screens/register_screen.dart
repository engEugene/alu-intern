import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

final class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

final class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameCtl = TextEditingController();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _fullnameCtl.dispose();
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).registerWithEmail(
      email: _emailCtl.text.trim(),
      password: _passwordCtl.text,
      fullname: _fullnameCtl.text.trim(),
      username: _usernameCtl.text.trim(),
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final theme = Theme.of(context);

    ref.listen(authProvider, (_, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Create Account', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _fullnameCtl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your full name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameCtl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Choose a username';
                      if (v.trim().length < 3) return 'Username must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (v) {
                      if (v != _passwordCtl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('I am signing up as', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        label: Text('Student'),
                        icon: Icon(Icons.school_outlined),
                      ),
                      ButtonSegment(
                        value: UserRole.startup,
                        label: Text('Startup'),
                        icon: Icon(Icons.business_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (selected) => setState(() => _role = selected.first),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Register'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
