import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads real Roboto glyphs for every test under this directory, so golden
/// images show actual text instead of Flutter's default blank test font
/// ("Ahem"). Rendering happens inside `flutter_tester`'s own engine rather
/// than the host OS, so this is stable across machines on the same Flutter
/// version; it does not depend on what fonts happen to be installed locally
/// or in CI.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await _loadRobotoFont();
  await _loadMaterialIconsFont();
  await testMain();
}

Future<void> _loadRobotoFont() async {
  final FontLoader loader = FontLoader('Roboto');
  for (final String fileName in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    loader.addFont(_loadFontFile('test/fonts/$fileName'));
  }
  await loader.load();
}

/// `Icon(Icons.xyz)` renders glyphs from the "MaterialIcons" font family
/// (looked up by codepoint), so it needs loading too or every Icon renders
/// as a blank box in goldens.
Future<void> _loadMaterialIconsFont() async {
  final FontLoader loader = FontLoader('MaterialIcons')
    ..addFont(_loadFontFile('test/fonts/MaterialIcons-Regular.otf'));
  await loader.load();
}

Future<ByteData> _loadFontFile(String path) async {
  final Uint8List bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}
