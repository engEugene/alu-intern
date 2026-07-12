import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String bytesToDataUri(Uint8List bytes, String mimeType) {
  final base64 = base64Encode(bytes);
  return 'data:$mimeType;base64,$base64';
}

ImageProvider? resolveImageProvider(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('data:')) {
    final commaIndex = source.indexOf(',');
    if (commaIndex == -1) return null;
    return MemoryImage(base64Decode(source.substring(commaIndex + 1)));
  }
  if (source.startsWith('http')) {
    return NetworkImage(source);
  }
  return null;
}

Future<void> openBase64Pdf(String base64Str) async {
  try {
    final String rawBase64;
    if (base64Str.contains(',')) {
      rawBase64 = base64Str.split(',')[1];
    } else {
      rawBase64 = base64Str;
    }
    final bytes = base64Decode(rawBase64);
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/resume_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    final uri = Uri.file(file.path);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}
}
