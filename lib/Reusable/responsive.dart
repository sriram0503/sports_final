import 'package:flutter/material.dart';

/// A widget that provides different UI builds based on screen width.
/// It distinguishes between mobile and tablet layouts.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobileBuilder,
    required this.tabletBuilder,
  });

  /// Builder function for mobile layouts (width < 650).
  final Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      )? mobileBuilder;

  /// Builder function for tablet layouts (width >= 650).
  final Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      )? tabletBuilder;

  /// Checks if the current screen width is considered mobile.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  /// Checks if the current screen width is considered tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1250 &&
          MediaQuery.of(context).size.width >= 650;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 650) {
          // If width is 650 or more, use tabletBuilder
          return tabletBuilder!(context, constraints);
        } else {
          // Otherwise, use mobileBuilder
          return mobileBuilder!(context, constraints);
        }
      },
    );
  }
}