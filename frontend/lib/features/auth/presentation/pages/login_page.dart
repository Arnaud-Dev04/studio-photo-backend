import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bokeh_painter.dart';
import '../../../../core/widgets/levitating_widget.dart';
import '../../../../core/widgets/studio_button.dart';
import '../../../../core/widgets/studio_text_field.dart';
import '../../providers/auth_provider.dart';

/// Écran de connexion luxueux avec bokeh animé et image flottante
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Arrière-plan : effet bokeh doré animé
          const Positioned.fill(
            child: AnimatedBokehBackground(circleCount: 10),
          ),

          // Contenu
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.04),

                    // Image appareil photo avec lévitation
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 0),
                      child: LevitatingWidget(
                        amplitude: 8,
                        duration: const Duration(milliseconds: 2000),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.gold.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 80,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Titre studio
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'STUDIO PHOTO',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Connectez-vous à votre espace',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // Message d'erreur
                    if (authState.status == AuthStatus.error) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage ?? 'Erreur de connexion',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Champ email
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 400),
                      child: StudioTextField(
                        controller: _emailController,
                        hintText: 'Adresse email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Champ mot de passe
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 500),
                      child: StudioTextField(
                        controller: _passwordController,
                        hintText: 'Mot de passe',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.gold,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 4) {
                            return 'Minimum 4 caractères';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Mot de passe oublié
                    FadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 550),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Mot de passe oublié
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton connexion
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 600),
                      child: SizedBox(
                        width: double.infinity,
                        child: StudioButton(
                          label: authState.status == AuthStatus.loading
                              ? 'Connexion...'
                              : 'Se connecter',
                          isLoading: authState.status == AuthStatus.loading,
                          icon: Icons.login_rounded,
                          onPressed: authState.status == AuthStatus.loading
                              ? null
                              : _handleLogin,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Footer
                    FadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 700),
                      child: Text(
                        '© 2025 Studio Photo · Bujumbura',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
