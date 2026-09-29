import 'package:flutter/material.dart';

/// The colours of the LeafScan design.
///
/// Do not write a hex value in any other file. A screen reads a colour here.
abstract final class AppColors {
  static const primary = Color(0xFF1558B0);
  static const primaryDark = Color(0xFF0B3A75);
  static const primaryLight = Color(0xFF1F6FD1);

  /// The tint behind an icon tile and a selected chip.
  static const tint = Color(0xFFEAF1FB);

  /// The ground of a scrolling list.
  static const ground = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);

  static const text = Color(0xFF122033);
  static const textStrong = Color(0xFF33445C);
  static const muted = Color(0xFF4F5F78);

  static const border = Color(0xFFD5E0EE);
  static const divider = Color(0xFFE3EAF3);

  /// The dashed outline of the photo drop area.
  static const dashed = Color(0xFF9FB7D6);

  /// The ground of a chip that is not selected.
  static const chipGrey = Color(0xFFF1F4F8);

  /// The ground behind a photo placeholder.
  static const imageGround = Color(0xFFE4EDF8);

  /// The text on a primary ground.
  static const onPrimary = Color(0xFFFFFFFF);

  /// The paragraph on the primary header block.
  static const onPrimaryMuted = Color(0xFFDCE8F8);
}
