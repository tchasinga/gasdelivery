import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rider marker: light green circle, white bike icon (larger, readable on the map).
Future<BitmapDescriptor> bitmapBicycleRiderMarker({
  double diameter = 64,
  Color backgroundColor = const ui.Color.fromARGB(255, 27, 66, 29),
  Color borderColor = const ui.Color.fromARGB(255, 18, 48, 20),
  Color iconColor = Colors.white,
  double iconSize = 20,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(diameter, diameter);
  final center = Offset(size.width / 2, size.height / 2);
  final radius = diameter / 2 - 2;

  canvas.drawCircle(center, radius, Paint()..color = backgroundColor);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final icon = Icons.two_wheeler;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: iconSize,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: iconColor,
    ),
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.ceil(), size.height.ceil());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
}

/// Plain icon bitmap (no background). Prefer [bitmapBicycleRiderMarker] for the rider pin.
Future<BitmapDescriptor> bitmapFromIcon(
  IconData icon, {
  Color color = const Color(0xFF014F5B),
  double size = 17,
}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: size,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: color,
    ),
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset.zero);
  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(
    textPainter.width.ceil(),
    textPainter.height.ceil(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
}
