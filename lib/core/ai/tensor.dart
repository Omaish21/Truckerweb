import 'dart:math' as math;

/// Lightweight, high-performance mathematical tensor and matrix library
/// implemented in pure Dart for client-side neural network inference.
class Tensor {
  final List<double> values;
  final List<int> shape;

  Tensor(this.values, this.shape);

  factory Tensor.zeros(List<int> shape) {
    final size = shape.reduce((a, b) => a * b);
    return Tensor(List<double>.filled(size, 0.0), shape);
  }

  factory Tensor.vector(List<double> values) {
    return Tensor(List<double>.from(values), [values.length]);
  }

  factory Tensor.matrix(List<List<double>> rows) {
    final numRows = rows.length;
    final numCols = rows.isNotEmpty ? rows[0].length : 0;
    final flat = <double>[];
    for (final row in rows) {
      flat.addAll(row);
    }
    return Tensor(flat, [numRows, numCols]);
  }

  int get length => values.length;
  List<double> get data => values;

  double operator [](int index) => values[index];
  void operator []=(int index, double val) => values[index] = val;

  /// Matrix-Vector Multiplication: y = W * x + b
  /// W is [outFeatures x inFeatures], x is [inFeatures], b is [outFeatures]
  static Tensor matmulVector(Tensor weights, Tensor input, [Tensor? bias]) {
    assert(weights.shape.length == 2, 'Weights must be 2D matrix');
    final outFeatures = weights.shape[0];
    final inFeatures = weights.shape[1];
    assert(input.length == inFeatures, 'Input dimension must match weights columns');

    final result = List<double>.filled(outFeatures, 0.0);
    for (int i = 0; i < outFeatures; i++) {
      double sum = (bias != null && bias.length > i) ? bias[i] : 0.0;
      final rowOffset = i * inFeatures;
      for (int j = 0; j < inFeatures; j++) {
        sum += weights.values[rowOffset + j] * input.values[j];
      }
      result[i] = sum;
    }
    return Tensor.vector(result);
  }

  /// Dot Product of two 1D vectors
  static double dot(Tensor a, Tensor b) {
    assert(a.length == b.length, 'Vectors must have identical length for dot product');
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a.values[i] * b.values[i];
    }
    return sum;
  }

  /// Cosine Similarity between two 1D vectors
  static double cosineSimilarity(Tensor a, Tensor b) {
    final dotProd = dot(a, b);
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      normA += a.values[i] * a.values[i];
      normB += b.values[i] * b.values[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProd / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Element-wise vector addition
  Tensor add(Tensor other) {
    assert(length == other.length, 'Tensors must have matching length for addition');
    final res = List<double>.generate(length, (i) => values[i] + other.values[i]);
    return Tensor(res, shape);
  }

  /// Element-wise scalar multiplication
  Tensor scale(double scalar) {
    final res = List<double>.generate(length, (i) => values[i] * scalar);
    return Tensor(res, shape);
  }

  /// Activation: Rectified Linear Unit (ReLU)
  Tensor relu() {
    final res = List<double>.generate(length, (i) => values[i] > 0 ? values[i] : 0.0);
    return Tensor(res, shape);
  }

  /// Activation: Gaussian Error Linear Unit (GELU)
  Tensor gelu() {
    const sqrt2OverPi = 0.7978845608; // sqrt(2 / pi)
    const coeff = 0.044715;
    final res = List<double>.generate(length, (i) {
      final x = values[i];
      final cube = x * x * x;
      final inner = sqrt2OverPi * (x + coeff * cube);
      return 0.5 * x * (1.0 + _fastTanh(inner));
    });
    return Tensor(res, shape);
  }

  /// Activation: Sigmoid (scaled to [0.0, 1.0])
  Tensor sigmoid() {
    final res = List<double>.generate(length, (i) {
      final x = values[i].clamp(-15.0, 15.0);
      return 1.0 / (1.0 + math.exp(-x));
    });
    return Tensor(res, shape);
  }

  /// Activation: Softmax over 1D vector with numeric stability
  Tensor softmax() {
    double maxVal = values.isNotEmpty ? values[0] : 0.0;
    for (int i = 1; i < length; i++) {
      if (values[i] > maxVal) maxVal = values[i];
    }

    double sumExp = 0.0;
    final exps = List<double>.filled(length, 0.0);
    for (int i = 0; i < length; i++) {
      final e = math.exp((values[i] - maxVal).clamp(-20.0, 20.0));
      exps[i] = e;
      sumExp += e;
    }

    if (sumExp == 0.0) sumExp = 1e-9;
    final res = List<double>.generate(length, (i) => exps[i] / sumExp);
    return Tensor(res, shape);
  }

  /// Layer Normalization over 1D vector
  Tensor layerNorm({double epsilon = 1e-5}) {
    if (length == 0) return this;
    double sum = 0.0;
    for (int i = 0; i < length; i++) {
      sum += values[i];
    }
    final mean = sum / length;

    double varSum = 0.0;
    for (int i = 0; i < length; i++) {
      final diff = values[i] - mean;
      varSum += diff * diff;
    }
    final std = math.sqrt(varSum / length + epsilon);

    final res = List<double>.generate(length, (i) => (values[i] - mean) / std);
    return Tensor(res, shape);
  }

  static double _fastTanh(double x) {
    if (x > 20.0) return 1.0;
    if (x < -20.0) return -1.0;
    final e2x = math.exp(2.0 * x);
    return (e2x - 1.0) / (e2x + 1.0);
  }
}
