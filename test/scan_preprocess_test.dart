import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:produceaiq/ml/scan_preprocess.dart';

/// Build a landscape test photo: left half red, right half blue.
img.Image _twoToneImage() {
  final image = img.Image(width: 40, height: 20);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final left = x < image.width ~/ 2;
      image.setPixelRgb(x, y, left ? 255 : 0, 0, left ? 0 : 255);
    }
  }
  return image;
}

Uint8List _encode(img.Image image) => Uint8List.fromList(img.encodeJpg(image));

/// Mean channel value over a rectangle of the flat HWC tensor.
double _mean(Float32List tensor, int size, int channel, int x0, int x1,
    int y0, int y1) {
  var sum = 0.0;
  var n = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      sum += tensor[(y * size + x) * 3 + channel];
      n++;
    }
  }
  return sum / n;
}

void main() {
  test('EXIF orientation is baked before the tensor is built', () {
    final image = _twoToneImage();

    // Same pixels twice: one file tagged "rotate 90" (portrait photo from a
    // phone), one file claiming it is already upright.
    final tagged = img.Image.from(image)
      ..exif.imageIfd.orientation = 6;
    final untagged = img.Image.from(image)..exif.imageIfd.orientation = 1;

    final taggedTensor =
        preprocessScanImageSync(_encode(tagged)).produceInput;
    final untaggedTensor =
        preprocessScanImageSync(_encode(untagged)).produceInput;

    // The raw JPEG pixels are landscape, so an un-oriented decode keeps the
    // red and blue halves on the LEFT/RIGHT. Baking orientation 6 turns the
    // halves into TOP/BOTTOM.
    const size = kProduceInputSize;
    const quarter = size ~/ 4;

    final untaggedLeftR = _mean(untaggedTensor, size, 0, 0, quarter, 0, size);
    final untaggedRightR =
        _mean(untaggedTensor, size, 0, size - quarter, size, 0, size);

    final taggedTopR = _mean(taggedTensor, size, 0, 0, size, 0, quarter);
    final taggedTopB =
        _mean(taggedTensor, size, 2, 0, size, 0, quarter);
    final taggedBottomR =
        _mean(taggedTensor, size, 0, 0, size, size - quarter, size);
    final taggedBottomB =
        _mean(taggedTensor, size, 2, 0, size, size - quarter, size);

    // Sanity: the untouched file really is red-left / blue-right.
    expect(untaggedLeftR, greaterThan(180));
    expect(untaggedRightR, lessThan(60));

    // With orientation 6 applied, one horizontal band is red and the other
    // is blue -- i.e. the image was rotated a quarter turn.
    final topIsRed = taggedTopR > 150 && taggedTopB < 90;
    final bottomIsBlue = taggedBottomR < 90 && taggedBottomB > 150;
    final topIsBlue = taggedTopB > 150 && taggedTopR < 90;
    final bottomIsRed = taggedBottomB < 90 && taggedBottomR > 150;

    expect(
      (topIsRed && bottomIsBlue) || (topIsBlue && bottomIsRed),
      isTrue,
      reason: 'orientation tag was ignored: tensor is still left/right '
          '(top R=${taggedTopR.toStringAsFixed(0)} '
          'B=${taggedTopB.toStringAsFixed(0)}, '
          'bottom R=${taggedBottomR.toStringAsFixed(0)} '
          'B=${taggedBottomB.toStringAsFixed(0)})',
    );
  });

  test('upright images are passed through unchanged', () {
    final image = _twoToneImage()..exif.imageIfd.orientation = 1;
    final tensor = preprocessScanImageSync(_encode(image)).produceInput;

    const size = kProduceInputSize;
    const quarter = size ~/ 4;
    expect(_mean(tensor, size, 0, 0, quarter, 0, size), greaterThan(180));
    expect(
        _mean(tensor, size, 0, size - quarter, size, 0, size), lessThan(60));
  });
}
