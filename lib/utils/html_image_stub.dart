// Stub for platforms that don't support HTML elements
import 'package:flutter/material.dart';

/// Build image widget (stub for non-web platforms)
/// This should never be called on iOS/Android as it's guarded by kIsWeb checks
Widget buildHtmlImage(String imageUrl, double width, double height) {
  throw UnimplementedError('HTML image rendering is only available on web');
}

