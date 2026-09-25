import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

/// Extrae la parte base64 de un data-URI (`;base64,`) o devuelve la cadena limpia.
String? extraerPayloadBase64(String entrada) {
  final trimmed = entrada.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  final b64Idx = lower.indexOf(';base64,');
  if (b64Idx >= 0) {
    return trimmed.substring(b64Idx + 8).replaceAll(RegExp(r'\s+'), '');
  }
  if (trimmed.startsWith('data:')) {
    final comma = trimmed.indexOf(',');
    if (comma >= 0) {
      return trimmed.substring(comma + 1).replaceAll(RegExp(r'\s+'), '');
    }
  }
  return trimmed.replaceAll(RegExp(r'\s+'), '');
}

Uint8List? _intentarDecodificarPayload(String payload) {
  if (payload.isEmpty) return null;
  try {
    return base64.decode(payload);
  } catch (_) {}
  try {
    return base64Url.decode(payload);
  } catch (_) {}
  final pad = (4 - payload.length % 4) % 4;
  final padded = payload + ('=' * pad);
  try {
    return base64.decode(padded);
  } catch (_) {}
  try {
    return base64Url.decode(padded);
  } catch (_) {}
  return null;
}

/// Decodifica bytes de imagen desde data-URI o cadena base64 (nunca lanza).
Uint8List? decodificarImagenBase64(String? entrada) {
  if (entrada == null) return null;
  final payload = extraerPayloadBase64(entrada);
  if (payload == null || payload.isEmpty) return null;
  var bytes = _intentarDecodificarPayload(payload);
  if (bytes != null) return bytes;
  // Reintento si el JSON trajo mojibake UTF-8/Latin-1 sobre la cadena.
  final corregida = fixEncoding(entrada).trim();
  if (corregida != entrada.trim()) {
    final p2 = extraerPayloadBase64(corregida);
    if (p2 != null) bytes = _intentarDecodificarPayload(p2);
  }
  return bytes;
}

/// Punto de entrada para [compute]: misma lógica que [decodificarImagenBase64].
Uint8List? decodificarImagenBase64Aislar(String entrada) {
  return decodificarImagenBase64(entrada);
}

/// Decodifica en segundo plano si la cadena es grande (evita bloquear el UI thread).
Future<Uint8List?> decodificarImagenBase64Async(String? entrada) async {
  if (entrada == null || entrada.trim().isEmpty) return null;
  final s = entrada.trim();
  const umbralAislar = 16384;
  if (s.length < umbralAislar) {
    return decodificarImagenBase64(s);
  }
  return compute(decodificarImagenBase64Aislar, s);
}
