import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/core/core.dart';

void main() {
  group('MathError Contract Hierarchy Tests', () {
    test('all mathematical error subclasses instantiate and preserve codes and messages', () {
      final errors = <MathError>[
        const DivisionByZeroError(),
        const DomainError(functionName: 'sqrt', argument: '-1'),
        const OverflowError(),
        const UnderflowError(),
        const InvalidExpressionError(position: 3),
        const SyntaxError(position: 5, token: '+'),
        const UnknownIdentifierError(identifier: 'x'),
        const UnknownFunctionError(functionName: 'foobar'),
        const InvalidArgumentError(argumentName: 'count', reason: 'negative'),
        const DimensionMismatchError(
          expectedDimension: 'length',
          actualDimension: 'mass',
        ),
        const InvalidUnitError(unit: 'kgg'),
        const MatrixDimensionError(
          operation: 'multiply',
          leftShape: (2, 3),
          rightShape: (4, 2),
        ),
        const SingularMatrixError(),
        const InvalidMatrixError(),
        const InvalidVectorError(),
        const NoSolutionError(),
        const InfiniteSolutionsError(),
        const ConvergenceFailureError(iterations: 100, method: 'bisection'),
        const PrecisionLossError(),
        const UnsupportedOperationError(operation: 'symbolic_integral'),
        const InvalidBaseError(base: 38),
        const InvalidBitWidthError(bitWidth: 12),
        const InvalidProbabilityError(value: 1.5),
        const InvalidDistributionParameterError(
          parameterName: 'lambda',
          reason: 'must be > 0',
        ),
        const FormulaInputMissingError(variableName: 'mass'),
        const FormulaInputInvalidError(
          variableName: 'radius',
          reason: 'cannot be negative',
        ),
        const CircularReferenceError(path: 'A1->B1->A1'),
        const DependencyError(dependencyName: 'Cell B2'),
        const GenericMathError(message: 'Miscellaneous calculation fault'),
      ];

      for (final error in errors) {
        expect(error.code, isNotEmpty);
        expect(error.message, isNotEmpty);
        expect(error.technicalMessage, equals(error.message));
        expect(error, isA<NexaMathError>());
      }
    });

    test('concrete error attributes are strongly typed and accessible', () {
      const syntax = SyntaxError(position: 10, token: ')');
      expect(syntax.position, equals(10));
      expect(syntax.token, equals(')'));

      const matrixDim = MatrixDimensionError(
        operation: 'add',
        leftShape: (2, 2),
        rightShape: (3, 3),
      );
      expect(matrixDim.leftShape, equals((2, 2)));
      expect(matrixDim.rightShape, equals((3, 3)));
    });
  });
}
