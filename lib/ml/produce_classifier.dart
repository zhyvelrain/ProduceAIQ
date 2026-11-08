import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'scan_preprocess.dart'
    show kProduceInputSize, preprocessScanImage, ScanPreprocessResult;

class Prediction {
  final String label;
  final double confidence;
  const Prediction(this.label, this.confidence);
  @override
  String toString() => 'Prediction($label, ${confidence.toStringAsFixed(3)})';
}

/// The classifier no longer decodes here -- see scan_preprocess.dart for
/// why. Input decoding/resizing happens once per photo, in one isolate,
/// shared with the freshness path.
class ProduceClassifier {
  static const int inputSize = kProduceInputSize;
  static const String _modelAsset = 'assets/produce_model.tflite';

  static const List<String> _trainingLabels = [
    'AMPALAYA', 'BANANA', 'KANGKONG', 'MANGO', 'OTHER', 'PAPAYA',
    'PINEAPPLE', 'SITAW', 'TALBOS_NG_KAMOTE', 'TALONG', 'WATERMELON',
  ];

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  Object? _lastLoadError;

  bool get isLoaded => _interpreter != null && _isolateInterpreter != null;
  Object? get lastLoadError => _lastLoadError;

  Future<void> loadModel() async {
    try {
      // FIX: use 4 CPU threads for the interpreter itself.
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

  static String _toRepositoryId(String l) => l.toLowerCase();

  /// Preprocessing (decode + resize) is shared via scan_preprocess.dart,
  /// so callers that ALSO need freshness can decode the photo once. This
  /// overload accepts an already-preprocessed result.
  Future<List<Prediction>> classifyPreprocessed(
    ScanPreprocessResult preprocessed,
  ) async {
    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter == null) {
      throw StateError('ProduceClassifier.loadModel() must complete first.');
    }

    final input = preprocessed.produceInput.reshape([
      1,
      kProduceInputSize,
      kProduceInputSize,
      3,
    ]);

    final output = [List<double>.filled(_trainingLabels.length, 0.0)];
    await isolateInterpreter.run(input, output);

    final probs = output[0];
    final predictions = <Prediction>[
      for (var i = 0; i < probs.length; i++)
        Prediction(_toRepositoryId(_trainingLabels[i]), probs[i]),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }

  Future<List<Prediction>> classify(File imageFile) async {
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

final produceClassifier = ProduceClassifier();