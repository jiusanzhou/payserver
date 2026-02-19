import 'package:flutter/material.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

class AppRouter {
  static Route<dynamic> generateRoute(
    Map<String, WidgetBuilder> routes,
    RouteSettings settings,
  ) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Route not found: ${settings.name}')),
      ),
    );
  }

  static RouteFactory buildRouteGenerator(Map<String, WidgetBuilder> routes) {
    return (settings) => generateRoute(routes, settings);
  }
}
