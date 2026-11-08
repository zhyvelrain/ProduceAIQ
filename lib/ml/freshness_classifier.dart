import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'scan_preprocess.dart'
    show kProduceInputSize, ScanPreprocessResult, preprocessScanImage;
import 'freshness_types.dart' show FreshnessGrade;
const String _modelAsset = 'assets/produce_freshness_model.tflite';

/// Alphabetical, matching train_freshness_model.py's folder order.
const List<String> _classLabels = ['OVERRIPE', 'RIPE', 'ROTTEN', 'UNRIPE'];

FreshnessGrade _labelToGrade(String label) {
  switch (label) {
    case 'OVERRIPE':
      return FreshnessGrade.overripe;
    case 'ROTTEN':
      return FreshnessGrade.rotten;
    case 'UNRIPE':
      return FreshnessGrade.unripe;
    case 'RIPE':
    default:
      return FreshnessGrade.ripe;
  }
}

/// FIX: the isolate -> UI copy is near-instant now that preprocessing is
/// shared (see scan_preprocess.dart) -- one decode per photo, not one
/// per classifier. Raw 0-255 values (preprocess_input is baked into the
/// .tflite graph).
class FreshnessClassifier {
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  Object? _lastLoadError;

  bool get isLoaded => _interpreter != null && _isolateInterpreter != null;
  Object? get lastLoadError => _lastLoadError;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      final interpreter =
          await Interpreter.fromAsset(_modelAsset, options: options);
      _interpreter = interpreter;
      _isolateInterpreter =
          await IsolateInterpreter.create(address: interpreter.address);
      _lastLoadError = null;
    } catch (e) {
      _interpreter = null;
      _isolateInterpreter = null;
      _lastLoadError = e;
      rethrow;
    }
  }

  Future<(FreshnessGrade, double)> classifyPreprocessed(
    ScanPreprocessResult preprocessed,
  ) async {
    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter == null) {
      throw StateError(
        'FreshnessClassifier.loadModel() must complete before classify() is called.',
      );
    }

    final input = preprocessed.produceInput.reshape([
      1,
      kProduceInputSize,
      kProduceInputSize,
      3,
    ]);

    final output = [List<double>.filled(_classLabels.length, 0.0)];
    await isolateInterpreter.run(input, output);

    final probs = output[0];
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return (_labelToGrade(_classLabels[best]), probs[best]);
  }

  Future<(FreshnessGrade, double)> classify(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final preprocessed = await preprocessScanImage(bytes);
    return classifyPreprocessed(preprocessed);
  }

  void dispose() {
    _isolateInterpreter?.close();
    _interpreter?.close();
    _interpreter = null;
    _isolateInterpreter = null;
  }
}

final freshnessClassifier = FreshnessClassifier();