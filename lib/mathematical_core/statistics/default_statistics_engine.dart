import 'package:nexa_math/core/result/math_result.dart';
import 'package:nexa_math/mathematical_core/common/math_value.dart';
import 'package:nexa_math/mathematical_core/common/precision_context.dart';
import 'package:nexa_math/mathematical_core/numeric/values/decimal_value.dart';
import 'package:nexa_math/mathematical_core/numeric/values/integer_value.dart';
import 'package:nexa_math/mathematical_core/statistics/bivariate/bivariate_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/descriptive/descriptive_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/descriptive/quantile_calculator.dart';
import 'package:nexa_math/mathematical_core/statistics/models/correlation_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/descriptive_statistics.dart';
import 'package:nexa_math/mathematical_core/statistics/models/paired_dataset.dart';
import 'package:nexa_math/mathematical_core/statistics/models/percentile_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_result.dart';
import 'package:nexa_math/mathematical_core/statistics/models/regression_type.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/linear_regression.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/polynomial_regression.dart';
import 'package:nexa_math/mathematical_core/statistics/regression/transformed_regression.dart';
import 'package:nexa_math/mathematical_core/statistics/statistics_engine.dart';

/// Production coordinator implementation of the [StatisticsEngine] interface.
final class DefaultStatisticsEngine implements StatisticsEngine {
  @override
  final PrecisionContext context;

  final DescriptiveCalculator _descriptiveCalculator;
  final QuantileCalculator _quantileCalculator;
  final BivariateCalculator _bivariateCalculator;
  final LinearRegression _linearRegression;
  final PolynomialRegression _quadraticRegression;
  final PolynomialRegression _cubicRegression;
  final TransformedRegression _logarithmicRegression;
  final TransformedRegression _exponentialRegression;
  final TransformedRegression _powerRegression;

  DefaultStatisticsEngine({this.context = PrecisionContext.standard})
    : _descriptiveCalculator = DescriptiveCalculator(context: context),
      _quantileCalculator = QuantileCalculator(context: context),
      _bivariateCalculator = BivariateCalculator(context: context),
      _linearRegression = LinearRegression(context: context),
      _quadraticRegression = PolynomialRegression(degree: 2, context: context),
      _cubicRegression = PolynomialRegression(degree: 3, context: context),
      _logarithmicRegression = const TransformedRegression(
        type: RegressionType.logarithmic,
      ),
      _exponentialRegression = const TransformedRegression(
        type: RegressionType.exponential,
      ),
      _powerRegression = const TransformedRegression(
        type: RegressionType.power,
      );

  // --- Univariate Descriptive Statistics ---

  @override
  IntegerValue count(Dataset dataset) => _descriptiveCalculator.count(dataset);

  @override
  MathResult<ScalarValue> sum(Dataset dataset) =>
      _descriptiveCalculator.sum(dataset);

  @override
  MathResult<ScalarValue> mean(Dataset dataset) =>
      _descriptiveCalculator.mean(dataset);

  @override
  MathResult<ScalarValue> median(Dataset dataset) =>
      _descriptiveCalculator.median(dataset);

  @override
  MathResult<List<ScalarValue>> mode(Dataset dataset) =>
      _descriptiveCalculator.mode(dataset);

  @override
  MathResult<ScalarValue> min(Dataset dataset) =>
      _descriptiveCalculator.min(dataset);

  @override
  MathResult<ScalarValue> max(Dataset dataset) =>
      _descriptiveCalculator.max(dataset);

  @override
  MathResult<ScalarValue> range(Dataset dataset) =>
      _descriptiveCalculator.range(dataset);

  @override
  MathResult<ScalarValue> populationVariance(Dataset dataset) =>
      _descriptiveCalculator.populationVariance(dataset);

  @override
  MathResult<ScalarValue> sampleVariance(Dataset dataset) =>
      _descriptiveCalculator.sampleVariance(dataset);

  @override
  MathResult<ScalarValue> populationStandardDeviation(Dataset dataset) =>
      _descriptiveCalculator.populationStandardDeviation(dataset);

  @override
  MathResult<ScalarValue> sampleStandardDeviation(Dataset dataset) =>
      _descriptiveCalculator.sampleStandardDeviation(dataset);

  @override
  MathResult<DescriptiveStatistics> descriptive(Dataset dataset) =>
      _descriptiveCalculator.calculateAll(dataset);

  // --- Quantiles and Quartiles ---

  @override
  MathResult<PercentileResult> percentile(
    Dataset dataset,
    ScalarValue percentile,
  ) => _quantileCalculator.percentile(dataset, percentile);

  @override
  MathResult<PercentileResult> percentileNum(Dataset dataset, num percentile) =>
      _quantileCalculator.percentileNum(dataset, percentile);

  @override
  MathResult<QuartileResult> quartiles(Dataset dataset) =>
      _quantileCalculator.quartiles(dataset);

  // --- Bivariate Statistics ---

  @override
  MathResult<ScalarValue> populationCovariance(PairedDataset dataset) =>
      _bivariateCalculator.populationCovariance(dataset);

  @override
  MathResult<ScalarValue> sampleCovariance(PairedDataset dataset) =>
      _bivariateCalculator.sampleCovariance(dataset);

  @override
  MathResult<DecimalValue> pearsonCorrelation(PairedDataset dataset) =>
      _bivariateCalculator.pearsonCorrelation(dataset);

  @override
  MathResult<CorrelationResult> correlation(PairedDataset dataset) =>
      _bivariateCalculator.calculateCorrelation(dataset);

  // --- Regression Analysis ---

  @override
  MathResult<RegressionResult> linearRegression(PairedDataset dataset) =>
      _linearRegression.fit(dataset);

  @override
  MathResult<RegressionResult> quadraticRegression(PairedDataset dataset) =>
      _quadraticRegression.fit(dataset);

  @override
  MathResult<RegressionResult> cubicRegression(PairedDataset dataset) =>
      _cubicRegression.fit(dataset);

  @override
  MathResult<RegressionResult> logarithmicRegression(PairedDataset dataset) =>
      _logarithmicRegression.fit(dataset);

  @override
  MathResult<RegressionResult> exponentialRegression(PairedDataset dataset) =>
      _exponentialRegression.fit(dataset);

  @override
  MathResult<RegressionResult> powerRegression(PairedDataset dataset) =>
      _powerRegression.fit(dataset);
}
