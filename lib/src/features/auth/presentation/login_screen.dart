import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:telos/src/common_widgets/app_button.dart';
import 'package:telos/src/common_widgets/app_text_field.dart';
import 'package:telos/src/exceptions/app_exception.dart';
import 'package:telos/src/routing/app_routes.dart';
import 'package:telos/src/features/auth/presentation/sign_in_controller.dart';

/// Login screen matching Banani "Calm Day Planner" design (Calm Mint theme).
/// Email/password only; encouraging copy per business rules.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthError() async {
    if (!mounted) return;
    final state = ref.read(signInControllerProvider);
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
    await ref.read(signInControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    await _handleAuthError();
    // Success: auth state will update and router redirects to home
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(signInControllerProvider.notifier).signInWithGoogle();
    await _handleAuthError();
  }

  Future<void> _signInWithApple() async {
    await ref.read(signInControllerProvider.notifier).signInWithApple();
    await _handleAuthError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CalmMint.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                const _LoginHeader(),
                const SizedBox(height: 40),
                _LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onToggleObscurePassword: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  onSubmit: _submit,
                  onSignInWithGoogle: _signInWithGoogle,
                  onSignInWithApple: _signInWithApple,
                ),
                // Footer: Sign up link
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

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
        color: _CalmMint.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/sun_logo.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(
            _CalmMint.primaryForeground,
            BlendMode.srcIn,
          ),
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
      'Welcome back',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: _CalmMint.foreground,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Ready to plan your day?',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _CalmMint.mutedForeground,
      ),
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
              color: _CalmMint.mutedForeground,
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.register),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _CalmMint.primary,
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

class _LoginForm extends ConsumerWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscurePassword,
    required this.onSubmit,
    required this.onSignInWithGoogle,
    required this.onSignInWithApple,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscurePassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onSignInWithGoogle;
  final Future<void> Function() onSignInWithApple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInControllerProvider);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Social auth first, matching Banani design
          _GoogleSocialButton(
            onPressed: state.isLoading ? null : onSignInWithGoogle,
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            onPressed: state.isLoading ? null : onSignInWithApple,
          ),
          const SizedBox(height: 8),
          const _SocialDivider(label: 'or use email'),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Email',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
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
            hint: 'Enter your password',
            controller: passwordController,
            obscureText: obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            autofillHints: const [AutofillHints.password],
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Enter your password';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: _CalmMint.mutedForeground,
              ),
              onPressed: onToggleObscurePassword,
            ),
          ),
          const SizedBox(height: 8),
          const _ForgotPasswordLink(),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: 'Log In',
            onPressed: onSubmit,
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
        const Expanded(
          child: Divider(
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _CalmMint.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppOutlineButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: _CalmMint.foreground,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSocialButton extends StatelessWidget {
  const _GoogleSocialButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppOutlineButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/google_logo.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Continue with Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Forgot password flow
        },
        child: Text(
          'Forgot password?',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: _CalmMint.mutedForeground,
          ),
        ),
      ),
    );
  }
}

/// Calm Mint theme tokens from Banani "Calm Day Planner" login design.
abstract final class _CalmMint {
  static const Color background = Color(0xFFF6FBF9);
  static const Color foreground = Color(0xFF0F1722);
  static const Color primary = Color(0xFF16A085);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color mutedForeground = Color(0xFF6B7280);
}
