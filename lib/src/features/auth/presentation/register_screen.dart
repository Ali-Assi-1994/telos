import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:telos/src/routing/app_routes.dart';

/// Placeholder register screen. Full sign-up form can be added next.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1722),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration form coming soon.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: const Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    color: Color(0xFF16A085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
