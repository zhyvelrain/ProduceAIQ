import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:image/image.dart' as img;
import 'submission.dart';

const int _thumbnailMaxWidth = 480;
const int _thumbnailJpegQuality = 65;

/// Compresses one photo down to a small JPEG thumbnail and returns it
/// as Base64 text. Runs via compute() on a background isolate -- see
/// produce_classifier.dart's _preprocessImageBytes for why: decode +
/// resize + JPEG-encode is real CPU work with no business blocking the
/// UI thread, especially now that a single submission can carry up to
/// 4 of these at once (one per scan attempt).
String? _encodeThumbnail(Uint8List bytes) {
  var decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Reviewers see a sideways photo if the EXIF Orientation tag is ignored;
  // decodeImage() does not rotate the pixels for us.
  if (decoded.exif.imageIfd.hasOrientation &&
      decoded.exif.imageIfd.orientation != 1) {
    decoded = img.bakeOrientation(decoded);
  }
  final resized = decoded.width > _thumbnailMaxWidth
      ? img.copyResize(decoded, width: _thumbnailMaxWidth)
      : decoded;
  final jpegBytes = img.encodeJpg(resized, quality: _thumbnailJpegQuality);
  return base64Encode(jpegBytes);
}

/// Sends unrecognized/unconfirmed-produce submissions to Firestore, where
/// the Admin Review Panel receives it real time.
///
/// IMPORTANT: this does NOT use Firebase Storage. As of Firebase's
/// September 2024 policy change, Cloud Storage requires the paid Blaze
/// plan -- projects on the free Spark plan (this one) get zero Storage
/// access, and any upload attempt fails with a 402/403 error. Rather
/// than require a billing account just for a thesis project, submitted
/// photos are compressed down to small thumbnails and stored directly
/// as Base64 strings on the Firestore document itself. Firestore
/// documents allow up to 1MB, and each compressed thumbnail (see
/// _thumbnailMaxWidth/_thumbnailJpegQuality above) comes out to
/// roughly 20-80KB -- comfortably within that limit even with several
/// attempts' worth of photos on one document.
///
/// Tradeoff, stated plainly: these are thumbnails for admin review,
/// not full-resolution archival copies of the original photos. If a
/// future need requires the originals, that's what upgrading to Blaze
/// and switching back to Storage would be for.
class SubmissionService {
  final _collection = FirebaseFirestore.instance.collection(
    'submissions',
  );

  /// [images] is every photo from the scan session that led to this
  /// submission, in attempt order (oldest first) -- not just the last
  /// one. A user who took 4 attempts before giving up may have
  /// captured the item from 4 different angles/distances; showing an
  /// admin only the final attempt's photo throws away that context
  /// for no reason, since every attempt's file is already on-device
  /// and available at submission time.
  ///
  /// Returns the created Firestore [DocumentReference] so the caller
  /// (GeneralMatchScreen) can patch the same document later -- e.g. once
  /// the user types a guessed name after the photo was already
  /// auto-submitted -- instead of writing a second, duplicate doc.
  Future<DocumentReference<Map<String, dynamic>>> submit(
    Submission submission, {
    List<File> images = const [],
  }) async {
    debugPrint(
      'SubmissionService.submit: received ${images.length} image(s) to '
      'thumbnail: ${images.map((f) => f.path).toList()}',
    );

    final thumbnails = <String>[];

    // Sequential rather than Future.wait: each compute() call spawns
    // its own isolate, and spawning several at once for what's a
    // background, non-blocking operation anyway isn't worth the
    // added memory/CPU contention on a phone mid-scan.
    for (final image in images) {
      try {
        final bytes = await image.readAsBytes();
        final thumbnail = await compute(_encodeThumbnail, bytes);
        if (thumbnail != null) {
          thumbnails.add(thumbnail);
        } else {
          debugPrint(
            'SubmissionService.submit: _encodeThumbnail returned null '
            'for ${image.path} (image package could not decode it)',
          );
        }
      } catch (e) {
        // Non-fatal: one failed thumbnail shouldn't drop the others,
        // or block the submission's text metadata from being useful
        // to an admin even with fewer (or zero) photos attached. BUT
        // this failure is now actually logged (it silently vanished
        // before this fix) -- e.g. a temp camera-capture file getting
        // cleaned up by the OS before submission would throw here as
        // a FileSystemException, and previously left zero trace.
        debugPrint(
          'SubmissionService.submit: failed to thumbnail ${image.path}: $e',
        );
      }
    }

    debugPrint(
      'SubmissionService.submit: ${thumbnails.length}/${images.length} '
      'thumbnails succeeded, writing submission now',
    );

    return _collection.add({
      ...submission.toMap(),
      // Kept as null (rather than removed) so any existing submissions
      // or admin-panel code expecting these singular fields don't
      // break -- they're simply never populated anymore in favor of
      // imageThumbnails below.
      'imageUrl': null,
      'imageThumbnailBase64': null,
      'imageThumbnails': thumbnails,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }
}

final submissionService = SubmissionService();