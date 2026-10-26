import 'package:flutter/material.dart';

/// Ikon kategori disimpan sebagai key string (bukan codePoint) agar
/// tree-shaking ikon saat build release tetap berjalan.
const Map<String, IconData> categoryIcons = {
  'venue': Icons.location_city,
  'catering': Icons.restaurant,
  'decor': Icons.local_florist,
  'makeup': Icons.face_retouching_natural,
  'dress': Icons.checkroom,
  'camera': Icons.photo_camera,
  'ring': Icons.diamond,
  'gift': Icons.card_giftcard,
  'mail': Icons.mail_outline,
  'music': Icons.music_note,
  'document': Icons.description,
  'car': Icons.directions_car,
  'hotel': Icons.hotel,
  'cake': Icons.cake,
  'celebration': Icons.celebration,
  'other': Icons.more_horiz,
};

IconData iconFor(String? key) => categoryIcons[key] ?? Icons.more_horiz;
