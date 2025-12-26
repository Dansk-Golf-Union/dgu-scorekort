// Web-specific HTML image rendering
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

/// Build HTML img element to bypass CORS restrictions (web only)
Widget buildHtmlImage(String imageUrl, double width, double height) {
  final String viewType = 'img-${imageUrl.hashCode}';
  
  // Register view factory (only once per unique URL)
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '4px';
      return img;
    },
  );

  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(4),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: HtmlElementView(viewType: viewType),
    ),
  );
}

