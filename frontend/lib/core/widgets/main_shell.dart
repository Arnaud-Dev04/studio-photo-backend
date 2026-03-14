import 'package:flutter/material.dart';
import 'studio_bottom_nav.dart';

/// Shell principal avec la bottom navigation bar
/// Contient les pages principales du studio
class MainShell extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  final ValueChanged<int> onNavigate;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onNavigate,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: StudioBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onNavigate,
      ),
    );
  }
}
