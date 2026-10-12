import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/statistics/default_statistics_engine.dart';
import 'package:nexa_math/mathematical_core/statistics/models/correlation_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/descriptive_statistics.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/percentile_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';

/// Primary public façade interface for the NexaMath Statistics & Regression Engine.
///
/// Coordinates univariate descriptive statistics, percentiles/quartiles, bivariate correlation,
/// and regression analysis (linear, quadratic, cubic, logarithmic, exponential, power).
abstract interface class StatisticsEngine {
  /// Default factory constructor returning the canonical production implementation.
  factory StatisticsEngine({PrecisionContext context}) =
      DefaultStatisticsEngine;

  /// Active precision context governing precision digits and rounding behavior.
  PrecisionContext get context;

  // --- Univariate Descriptive Statistics ---

  /// Computes the number of observations $N = |\mathcal{D}|$.
  IntegerValue count(Dataset dataset);

  /// Computes the sum of all observations: $\sum x_i$.
  MathResult<ScalarValue> sum(Dataset dataset);

  /// Computes the arithmetic mean: $\bar{x} = \frac{1}{N}\sum x_i$.
  MathResult<ScalarValue> mean(Dataset dataset);

  /// Computes the sample median.
  MathResult<ScalarValue> median(Dataset dataset);

  /// Computes the mode values according to the NexaMath Mode Convention.
  MathResult<List<ScalarValue>> mode(Dataset dataset);

  /// Computes the minimum observed value.
  MathResult<ScalarValue> min(Dataset dataset);

  /// Computes the maximum observed value.
  MathResult<ScalarValue> max(Dataset dataset);

  /// Computes the statistical range: $\max - \min$.
  MathResult<ScalarValue> range(Dataset dataset);

  /// Computes population variance: $\sigma^2 = \frac{1}{N}\sum (x_i - \bar{x})^2$.
  MathResult<ScalarValue> populationVariance(Dataset dataset);

  /// Computes sample variance: $s^2 = \frac{1}{N-1}\sum (x_i - \bar{x})^2$ ($N \ge 2$).
  MathResult<ScalarValue> sampleVariance(Dataset dataset);

  /// Computes population standard deviation: $\sigma = \sqrt{\sigma^2}$.
  MathResult<ScalarValue> populationStandardDeviation(Dataset dataset);

  /// Computes sample standard deviation: $s = \sqrt{s^2}$ ($N \ge 2$).
  MathResult<ScalarValue> sampleStandardDeviation(Dataset dataset);

  /// Aggregates all univariate descriptive metrics into an immutable container.
  MathResult<DescriptiveStatistics> descriptive(Dataset dataset);

  // --- Quantiles and Quartiles ---

  /// Computes the percentile $P_p$ for $p \in [0, 100]$ using Hyndman-Fan Type 7 linear interpolation.
  MathResult<PercentileResult> percentile(
    Dataset dataset,
    ScalarValue percentile,
  );

  /// Convenience percentile method accepting platform double/num.
  MathResult<PercentileResult> percentileNum(Dataset dataset, num percentile);

  /// Computes five-number summary quartiles ($Q_0, Q_1, Q_2, Q_3, Q_4$) and $\text{IQR} = Q_3 - Q_1$.
  MathResult<QuartileResult> quartiles(Dataset dataset);

  // --- Bivariate Statistics ---

  /// Computes population covariance: $\operatorname{Cov}_{\text{pop}}(X, Y)$.
  MathResult<ScalarValue> populationCovariance(PairedDataset dataset);

  /// Computes sample covariance: $\operatorname{Cov}_{\text{sample}}(X, Y)$ ($N \ge 2$).
  MathResult<ScalarValue> sampleCovariance(PairedDataset dataset);

  /// Computes Pearson correlation coefficient $r \in [-1, 1]$.
  MathResult<DecimalValue> pearsonCorrelation(PairedDataset dataset);

  /// Computes complete correlation analysis (covariances and Pearson $r$).
  MathResult<CorrelationResult> correlation(PairedDataset dataset);

  // --- Regression Analysis ---

  /// Fits Ordinary Least Squares (OLS) Linear Regression: $y = a x + b$.
  MathResult<RegressionResult> linearRegression(PairedDataset dataset);

  /// Fits Quadratic Polynomial Regression: $y = a x^2 + b x + c$.
  MathResult<RegressionResult> quadraticRegression(PairedDataset dataset);

  /// Fits Cubic Polynomial Regression: $y = a x^3 + b x^2 + c x + d$.
  MathResult<RegressionResult> cubicRegression(PairedDataset dataset);

  /// Fits Logarithmic Regression: $y = a + b \ln(x)$ ($x > 0$).
  MathResult<RegressionResult> logarithmicRegression(PairedDataset dataset);

  /// Fits Exponential Regression: $y = a e^{b x}$ ($y > 0$, $a > 0$).
  MathResult<RegressionResult> exponentialRegression(PairedDataset dataset);

  /// Fits Power Regression: $y = a x^b$ ($x > 0, y > 0$, $a > 0$).
  MathResult<RegressionResult> powerRegression(PairedDataset dataset);
}
