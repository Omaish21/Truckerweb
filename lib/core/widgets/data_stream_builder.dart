import 'package:flutter/material.dart';

/// Lightweight, resilient StreamBuilder wrapper with fallback data support.
/// Zero third-party dependency; pure Flutter widget.
class DataStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final T? fallbackData;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const DataStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.fallbackData,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (fallbackData != null) {
            return builder(context, fallbackData as T);
          }
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!);
          }
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          if (fallbackData != null) {
            return builder(context, fallbackData as T);
          }
          return loadingWidget ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2.2));
        }

        final data = snapshot.data ?? fallbackData;
        if (data != null) {
          return builder(context, data);
        }

        return loadingWidget ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2.2));
      },
    );
  }
}
