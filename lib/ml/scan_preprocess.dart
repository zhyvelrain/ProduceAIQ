import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Shared, single-decode preprocessing for the scan pipeline.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// The scan flow used to decode and resize the SAME phone photo three
/// separate times, each in its own background isolate spawned by
/// compute():
///
///   1. produce_classifier._preprocessImageBytes  -> decode, resize 224x224
///   2. freshness_classifier._preprocessImageBytes -> decode, resize 224x224
///   3. freshness_assessor._computeFreshnessHeuristic -> decode, resize 96x96
///
/// On a 12MP+ camera photo that is three full JPEG decodes plus three
/// isolate spawn/teardown cycles, all awaited sequentially per scan.
/// That triple cost -- not the model inference -- is what made a scan
/// "freeze" after the shutter. It scales with the camera's resolution,
/// which is exactly why it felt worst on high-megapixel phones.
///
/// THE FIX: decode ONCE. All consumers need the same source image, so
/// this module decodes a single img.Image and derives every downstream
/// tensor (the 224x224 model input and the 96x96 freshness sample) from
/// that one decoded object. Two fewer decodes and two fewer isolate
/// spawns per scan, all in one background isolate. Values stay raw
/// [0,255] -- both .tflite models have preprocess_input baked into the
/// graph, so no normalization here.

/// Produce (species) model input size -- MobileNetV2 / ImageNet native.
const int kProduceInputSize = 224;

/// Freshness heuristic sample size -- coarse color statistics only.
const int kFreshnessSampleSize = 96;

/// Result of one decode: the produce tensor plus, cheaply derived from
/// the same decoded image, the freshness color sample.
class ScanPreprocessResult {
  /// Flat HWC RGB buffer, [kProduceInputSize]^2 * 3 floats, raw 0-255.
  /// Feed straight into the produce model's interpreter.
  final Float32List produceInput;

  /// Flat HWC RGB buffer, [kFreshnessSampleSize]^2 * 3 floats, raw 0-255.
  /// Same image as [produceInput], only smaller -- used by the freshness
  /// heuristic so it never re-decodes.
  final Float32List freshnessSample;

  const ScanPreprocessResult(this.produceInput, this.freshnessSample);
}

/// Decode [bytes] once and build both tensors. Top-level so it runs via
/// compute() on a background isolate.
ScanPreprocessResult _decodeAndBuild(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode image bytes');
  }

  final upright = _bakeExifOrientation(decoded);

  return ScanPreprocessResult(
    _toFloatBuffer(upright, kProduceInputSize),
    _toFloatBuffer(upright, kFreshnessSampleSize),
  );
}

/// Rotate the pixels to match the EXIF Orientation tag.
///
/// package:image's decodeImage() returns the JPEG's raw pixel buffer plus
/// the orientation tag -- it does NOT rotate the pixels. A phone held in
/// portrait commonly stores a landscape buffer tagged "rotate 90", so
/// without this step the resized 224x224 tensor is the scene turned on its
/// side. Both classifiers were trained on upright photos, so a sideways
/// input is a one-step-removed version of the training distribution.
///
/// bakeOrientation() copies the image, which is expensive on a 12MP+ photo,
/// hence the early return when the tag is absent or already 1 (upright).
img.Image _bakeExifOrientation(img.Image decoded) {
  final ifd = decoded.exif.imageIfd;
  if (!ifd.hasOrientation || ifd.orientation == 1) {
    return decoded;
  }
  return img.bakeOrientation(decoded);
}

/// Resize [src] to [size]x[size] and flatten to an HWC Float32List of
/// raw 0-255 channel values.
Float32List _toFloatBuffer(img.Image src, int size) {
  final resized = img.copyResize(
    src,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  final buffer = Float32List(size * size * 3);
  var i = 0;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final p = resized.getPixel(x, y);
      buffer[i++] = p.r.toDouble();
      buffer[i++] = p.g.toDouble();
      buffer[i++] = p.b.toDouble();
    }
  }
  return buffer;
}

/// Decode+resize on a background isolate so the UI thread never blocks
/// on it. One compute() call, one isolate, one decode, both tensors.
Future<ScanPreprocessResult> preprocessScanImage(Uint8List bytes) {
  return compute(_decodeAndBuild, bytes);
}

/// Synchronous entry point -- used by tests and by any caller already
/// on a background isolate (so it doesn't spawn a nested one).
ScanPreprocessResult preprocessScanImageSync(Uint8List bytes) {
  return _decodeAndBuild(bytes);
}
