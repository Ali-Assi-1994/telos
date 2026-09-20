import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:telos/src/common_widgets/app_button.dart';
import 'package:telos/src/common_widgets/app_text_field.dart';
import 'package:telos/src/constants/app_colors.dart';
import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/features/auth/presentation/auth_controller.dart';
import 'package:telos/src/routing/app_routes.dart';

/// Signup screen matching Banani "Calm Day Planner" Signup Page design.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthError() async {
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((state.error! as AppException).toUserMessage()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    await _handleAuthError();
    // On success, auth state provider + router will take over navigation.
  }

  Future<void> _signUpWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    await _handleAuthError();
  }

  Future<void> _signUpWithApple() async {
    await ref.read(authControllerProvider.notifier).signInWithApple();
    await _handleAuthError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calmBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                const _SignupHeader(),
                const SizedBox(height: 40),
                _SignupForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onToggleObscurePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _submit,
                  onSignUpWithGoogle: _signUpWithGoogle,
                  onSignUpWithApple: _signUpWithApple,
                ),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Logo(),
        SizedBox(height: 20),
        _Title(),
        SizedBox(height: 4),
        _Subtitle(),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.calmPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.wb_sunny_rounded,
          size: 32,
          color: AppColors.calmPrimaryForeground,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Create an account',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.calmForeground,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Start organizing your tasks today',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.calmMutedForeground,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 24),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.calmMutedForeground,
            ),
            children: [
              const TextSpan(text: 'Already have an account? '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.calmPrimary,
                    ),
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

class _SignupForm extends ConsumerWidget {
  const _SignupForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.onSubmit,
    required this.onSignUpWithGoogle,
    required this.onSignUpWithApple,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onSignUpWithGoogle;
  final Future<void> Function() onSignUpWithApple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppOutlineButton(
            onPressed: state.isLoading ? null : onSignUpWithGoogle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/google_logo.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign up with Google',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppOutlineButton(
            onPressed: state.isLoading ? null : onSignUpWithApple,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.apple, size: 20, color: AppColors.calmForeground),
                SizedBox(width: 12),
                Text(
                  'Sign up with Apple',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SocialDivider(label: 'or use email'),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Full Name',
            hint: 'Jane Doe',
            controller: nameController,
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline_rounded,
            autofillHints: const [AutofillHints.name],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Email',
            hint: 'name@example.com',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Password',
            hint: 'Create a password',
            controller: passwordController,
            obscureText: obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Create a password';
              }
              if (v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.calmMutedForeground,
              ),
              onPressed: onToggleObscurePassword,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Sign Up',
            onPressed: state.isLoading ? null : onSubmit,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider({this.label = 'or continue with'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Divider(thickness: 1, color: theme.colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(thickness: 1, color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
