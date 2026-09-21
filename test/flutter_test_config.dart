import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real Roboto/Material Icons glyphs for every test under this
/// directory, so golden images show actual text and icons instead of
/// Flutter's default blank test font ("Ahem"), and installs a
/// small-tolerance golden comparator.
///
/// The tolerance matters in practice, not just in theory: goldens generated
/// on macOS showed small pixel diffs (0.2% to 1.3%) when the exact same
/// widgets were rendered in CI on Ubuntu, despite using the same Flutter SDK
/// version and the same embedded font files. That's subpixel antialiasing
/// differing by host OS/GPU driver inside `flutter_tester`'s own rendering,
/// not a real visual regression; a real layout, color, or content change
/// produces a much larger diff than this.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await _loadRobotoFont();
  await _loadMaterialIconsFont();
  goldenFileComparator = _TolerantGoldenFileComparator(
    // LocalFileComparator derives basedir via dirname() on this URI, so it
    // needs a file-shaped path (a trailing directory segment would strip
    // "golden" as if it were the filename). All golden tests currently live
    // directly under test/golden/, so this fixed basedir is correct for all
    // of them. If a golden test is ever added outside that directory, this
    // needs revisiting.
    Uri.parse('test/golden/_.dart'),
    precisionTolerance: 0.02,
  );
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

/// Straight from `GoldenFileComparator`'s own documentation
/// (package:flutter_test/src/goldens.dart), which recommends exactly this
/// pattern for projects that need tolerance for cross-platform rendering
/// noise.
class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         precisionTolerance >= 0 && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  /// How much the golden image can differ from the test image, from 0 (no
  /// difference) to 1 (completely different images).
  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final bool passed =
        result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
