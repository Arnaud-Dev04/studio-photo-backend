import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les locales françaises pour les dates
  await initializeDateFormatting('fr_FR', null);

  runApp(const ProviderScope(child: StudioPhotoApp()));
}

/// Application principale du studio photo
class StudioPhotoApp extends ConsumerStatefulWidget {
  const StudioPhotoApp({super.key});

  @override
  ConsumerState<StudioPhotoApp> createState() => _StudioPhotoAppState();
}

class _StudioPhotoAppState extends ConsumerState<StudioPhotoApp> {
  @override
  void initState() {
    super.initState();
    // Initialiser l'authentification au démarrage
    Future.microtask(() {
      ref.read(authProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Studio Photo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      locale: const Locale('fr', 'FR'),
    );
  }
}
