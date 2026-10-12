import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';

/// Base contract for all mathematical regression estimators in NexaMath.
abstract interface class RegressionModel {
  /// Fits the regression model to the given paired dataset.
  MathResult<RegressionResult> fit(PairedDataset dataset);
}
