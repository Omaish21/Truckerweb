import 'tensor.dart';

enum ActivationType { none, relu, gelu, sigmoid, softmax }

/// A standard fully-connected feedforward neural network layer.
class DenseLayer {
  final Tensor weights; // [outFeatures x inFeatures]
  final Tensor bias; // [outFeatures]
  final ActivationType activation;

  DenseLayer({
    required this.weights,
    required this.bias,
    this.activation = ActivationType.relu,
  });

  factory DenseLayer.random(int inFeatures, int outFeatures, {
    ActivationType activation = ActivationType.relu,
    double weightScale = 0.1,
  }) {
    // He / Xavier initialization approximation
    final values = List<double>.generate(
      outFeatures * inFeatures,
      (i) => ((i * 17 + 13) % 100 - 50) / 100.0 * weightScale,
    );
    final biases = List<double>.filled(outFeatures, 0.01);
    return DenseLayer(
      weights: Tensor(values, [outFeatures, inFeatures]),
      bias: Tensor.vector(biases),
      activation: activation,
    );
  }

  Tensor forward(Tensor input) {
    Tensor linear = Tensor.matmulVector(weights, input, bias);
    switch (activation) {
      case ActivationType.relu:
        return linear.relu();
      case ActivationType.gelu:
        return linear.gelu();
      case ActivationType.sigmoid:
        return linear.sigmoid();
      case ActivationType.softmax:
        return linear.softmax();
      case ActivationType.none:
        return linear;
    }
  }
}

/// Residual Block with Skip Connection & Layer Normalization:
/// y = LayerNorm(x + Activation(W * x + b))
class ResidualBlock {
  final DenseLayer dense;

  ResidualBlock({required this.dense});

  Tensor forward(Tensor input) {
    assert(
      dense.weights.shape[0] == dense.weights.shape[1],
      'Residual block requires identical inFeatures and outFeatures',
    );
    final proj = dense.forward(input);
    final withSkip = input.add(proj);
    return withSkip.layerNorm();
  }
}

/// Embedding layer that maps an integer token ID to a continuous vector representation
class EmbeddingLayer {
  final int vocabularySize;
  final int embeddingDim;
  final List<List<double>> embeddings;

  EmbeddingLayer({
    required this.vocabularySize,
    required this.embeddingDim,
    required this.embeddings,
  });

  factory EmbeddingLayer.initialized(int vocabSize, int dim) {
    final matrix = List<List<double>>.generate(vocabSize, (row) {
      return List<double>.generate(
        dim,
        (col) => (((row * 31 + col * 19) % 100) - 50) / 100.0 * 0.2,
      );
    });
    return EmbeddingLayer(
      vocabularySize: vocabSize,
      embeddingDim: dim,
      embeddings: matrix,
    );
  }

  Tensor lookup(int index) {
    final safeIdx = (index >= 0 && index < vocabularySize) ? index : 0;
    return Tensor.vector(embeddings[safeIdx]);
  }
}
