import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/rentals/presentation/pages/materials_page.dart';
import '../../features/rentals/presentation/pages/material_detail_page.dart';
import '../../features/rentals/presentation/pages/material_form_page.dart';
import '../../features/rentals/presentation/pages/rental_form_page.dart';
import '../../features/rentals/presentation/pages/rental_return_page.dart';
import '../../features/rentals/presentation/pages/qr_scanner_page.dart';
import '../../features/gallery/presentation/pages/gallery_page.dart';
import '../../features/team/presentation/pages/team_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../widgets/main_shell.dart';

/// Configuration du routeur GoRouter avec transitions personnalisées
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/login';

      // Si pas connecté et pas sur une route auth → redirect login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Si connecté et sur login → redirect dashboard
      if (isLoggedIn && state.matchedLocation == '/login') return '/dashboard';

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildPage(
          const SplashPage(),
          state,
        ),
      ),

      // Login
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(
          const LoginPage(),
          state,
        ),
      ),

      // Shell avec bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          // Déterminer l'index actif basé sur la route
          int currentIndex = 0;
          final location = state.matchedLocation;
          if (location.startsWith('/materials') || location.startsWith('/scanner')) {
            currentIndex = 1;
          } else if (location.startsWith('/gallery')) {
            currentIndex = 2;
          } else if (location.startsWith('/team')) {
            currentIndex = 3;
          } else if (location.startsWith('/finance')) {
            currentIndex = 4;
          }

          return MainShell(
            currentIndex: currentIndex,
            onNavigate: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                case 1:
                  context.go('/materials');
                case 2:
                  context.go('/gallery');
                case 3:
                  context.go('/team');
                case 4:
                  context.go('/finance');
              }
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _buildPage(
              const DashboardPage(),
              state,
            ),
          ),

          // ═══════════════════════════════════════════
          // MATÉRIELS & LOCATIONS
          // ═══════════════════════════════════════════
          GoRoute(
            path: '/materials',
            pageBuilder: (context, state) => _buildPage(
              const MaterialsPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/materials/new',
            pageBuilder: (context, state) => _buildPage(
              const MaterialFormPage(),
              state,
            ),
          ),
          GoRoute(
            path: '/materials/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _buildPage(
                MaterialDetailPage(materialId: id),
                state,
              );
            },
          ),
          GoRoute(
            path: '/materials/:id/edit',
            pageBuilder: (context, state) {
              // Le matériel sera chargé par le provider
              return _buildPage(
                const MaterialFormPage(),
                state,
              );
            },
          ),
          GoRoute(
            path: '/rentals/new',
            pageBuilder: (context, state) {
              final materialIdStr = state.uri.queryParameters['materialId'];
              final materialId = materialIdStr != null
                  ? int.tryParse(materialIdStr)
                  : null;
              return _buildPage(
                RentalFormPage(materialId: materialId),
                state,
              );
            },
          ),
          GoRoute(
            path: '/rentals/:id/return',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _buildPage(
                RentalReturnPage(rentalId: id),
                state,
              );
            },
          ),
          GoRoute(
            path: '/scanner',
            pageBuilder: (context, state) => _buildPage(
              const QrScannerPage(),
              state,
            ),
          ),

          // ═══════════════════════════════════════════
          // GALERIE
          // ═══════════════════════════════════════════
          GoRoute(
            path: '/gallery',
            pageBuilder: (context, state) => _buildPage(
              const GalleryPage(),
              state,
            ),
          ),

          // ═══════════════════════════════════════════
          // ÉQUIPE
          // ═══════════════════════════════════════════
          GoRoute(
            path: '/team',
            pageBuilder: (context, state) => _buildPage(
              const TeamPage(),
              state,
            ),
          ),

          // ═══════════════════════════════════════════
          // FINANCE
          // ═══════════════════════════════════════════
          GoRoute(
            path: '/finance',
            pageBuilder: (context, state) => _buildPage(
              const FinancePage(),
              state,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Transition personnalisée : Fade + Slide subtil
CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
