import 'package:flutter/material.dart';

/// Breakpoints centralisés pour l'application BOUSSELHA CARS.
///
/// - mobile  : largeur < 600
/// - tablet  : 600 ≤ largeur < 1100
/// - desktop : largeur ≥ 1100
abstract final class Responsive {
  static const double mobileBreak = 600;
  static const double tabletBreak = 1100;

  /// Retourne true si l'écran est de taille mobile (< 600px).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreak;

  /// Retourne true si l'écran est de taille tablette (600–1100px).
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreak && w < tabletBreak;
  }

  /// Retourne true si l'écran est de taille desktop (≥ 1100px).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreak;

  /// Retourne true si l'écran est tablet ou plus grand (≥ 600px).
  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreak;

  /// Retourne une valeur selon la taille de l'écran.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Padding horizontal adaptatif.
  static EdgeInsets horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 24);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 12);
  }

  /// Padding de page complet adaptatif.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(20);
    if (isTablet(context)) return const EdgeInsets.all(14);
    return const EdgeInsets.all(10);
  }
}

/// Widget builder adaptatif selon la taille d'écran.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return desktop(context);
    if (Responsive.isTablet(context)) return (tablet ?? desktop)(context);
    return mobile(context);
  }
}
