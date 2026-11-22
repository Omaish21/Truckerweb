import 'package:flutter/widgets.dart';

/// Pure Flutter InheritedNotifier Provider.
/// High-performance, zero third-party dependency state management.
class AppProvider<T extends Listenable> extends InheritedNotifier<T> {
  const AppProvider({
    super.key,
    required T super.notifier,
    required super.child,
  });

  /// Retrieves the notifier and registers the calling context to rebuild when notified.
  static T of<T extends Listenable>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppProvider<T>>();
    assert(provider != null, 'No AppProvider<$T> found in the widget tree.');
    return provider!.notifier!;
  }

  /// Retrieves the notifier without subscribing the calling context to rebuilds.
  static T read<T extends Listenable>(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppProvider<T>>();
    final provider = element?.widget as AppProvider<T>?;
    assert(provider != null, 'No AppProvider<$T> found in the widget tree.');
    return provider!.notifier!;
  }
}

/// InheritedWidget for non-listenable singleton services (e.g. FirebaseService, GeocodingService).
class ServiceProvider<T> extends InheritedWidget {
  final T service;

  const ServiceProvider({
    super.key,
    required this.service,
    required super.child,
  });

  static T of<T>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ServiceProvider<T>>();
    assert(provider != null, 'No ServiceProvider<$T> found in the widget tree.');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(covariant ServiceProvider<T> oldWidget) =>
      service != oldWidget.service;
}

/// Convenient extension methods on BuildContext for clean, readable code
extension AppProviderContextExtension on BuildContext {
  /// Watch a Listenable/ChangeNotifier provider and rebuild when it emits changes
  T watch<T extends Listenable>() => AppProvider.of<T>(this);

  /// Read a Listenable/ChangeNotifier provider without triggering a rebuild
  T read<T extends Listenable>() => AppProvider.read<T>(this);

  /// Retrieve a singleton service
  T service<T>() => ServiceProvider.of<T>(this);
}
