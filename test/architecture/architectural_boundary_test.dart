import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural Boundaries Enforcer', () {
    /// Extracts all import and export target URIs from Dart source files in [dir].
    /// Handles multiline directives, single/double quotes, and varied whitespace.
    Iterable<({File file, String uri, int lineNumber})> extractDirectives(
      Directory dir,
    ) sync* {
      if (!dir.existsSync()) return;

      final directiveRegex = RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );

      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final matches = directiveRegex.allMatches(content);
        for (final match in matches) {
          final uri = match.group(1)!;
          // Calculate 1-indexed line number
          final lineNumber = content
              .substring(0, match.start)
              .split('\n')
              .length;
          yield (file: file, uri: uri, lineNumber: lineNumber);
        }
      }
    }

    test('Mathematical Core must never import Flutter, platform APIs, or upper layers', () {
      final mathCoreDir = Directory('lib/mathematical_core');
      expect(
        mathCoreDir.existsSync(),
        isTrue,
        reason: 'lib/mathematical_core directory must exist',
      );

      final forbiddenPrefixes = [
        'package:flutter/',
        'package:flutter_test/',
        'dart:ui',
        'dart:html',
        'dart:io',
        'package:nexa_math/presentation/',
        'package:nexa_math/infrastructure/',
        'package:nexa_math/application/',
      ];

      for (final item in extractDirectives(mathCoreDir)) {
        for (final forbidden in forbiddenPrefixes) {
          expect(
            item.uri.startsWith(forbidden),
            isFalse,
            reason:
                'Mathematical Core violation in ${item.file.path}:${item.lineNumber}: '
                'Imports/exports forbidden target "$forbidden" via "${item.uri}".',
          );
        }

        // Relative path escapes to upper layers
        if (item.uri.startsWith('../')) {
          final normalized = item.uri.replaceAll(r'\', '/');
          expect(
            normalized.contains('../application/') ||
                normalized.contains('../infrastructure/') ||
                normalized.contains('../presentation/'),
            isFalse,
            reason:
                'Mathematical Core violation in ${item.file.path}:${item.lineNumber}: '
                'Escapes to upper layer via relative import "${item.uri}".',
          );
        }
      }
    });

    test('Core must never import upper layers, Flutter, or platform UI', () {
      final coreDir = Directory('lib/core');
      expect(
        coreDir.existsSync(),
        isTrue,
        reason: 'lib/core directory must exist',
      );

      final forbiddenPrefixes = [
        'package:flutter/',
        'package:flutter_test/',
        'dart:ui',
        'dart:html',
        'package:nexa_math/mathematical_core/',
        'package:nexa_math/application/',
        'package:nexa_math/infrastructure/',
        'package:nexa_math/presentation/',
      ];

      for (final item in extractDirectives(coreDir)) {
        for (final forbidden in forbiddenPrefixes) {
          expect(
            item.uri.startsWith(forbidden),
            isFalse,
            reason:
                'Core layer violation in ${item.file.path}:${item.lineNumber}: '
                'Imports/exports forbidden target "$forbidden" via "${item.uri}".',
          );
        }

        // Relative path escapes to other layers
        if (item.uri.startsWith('../')) {
          final normalized = item.uri.replaceAll(r'\', '/');
          expect(
            normalized.contains('../mathematical_core/') ||
                normalized.contains('../application/') ||
                normalized.contains('../infrastructure/') ||
                normalized.contains('../presentation/'),
            isFalse,
            reason:
                'Core layer violation in ${item.file.path}:${item.lineNumber}: '
                'Escapes to another layer via relative import "${item.uri}".',
          );
        }
      }
    });

    test('Application must never import Presentation or concrete Infrastructure', () {
      final appDir = Directory('lib/application');
      expect(
        appDir.existsSync(),
        isTrue,
        reason: 'lib/application directory must exist',
      );

      final forbiddenPrefixes = [
        'package:flutter/',
        'dart:ui',
        'package:nexa_math/presentation/',
        'package:nexa_math/infrastructure/',
      ];

      for (final item in extractDirectives(appDir)) {
        for (final forbidden in forbiddenPrefixes) {
          expect(
            item.uri.startsWith(forbidden),
            isFalse,
            reason:
                'Application layer violation in ${item.file.path}:${item.lineNumber}: '
                'Imports/exports forbidden target "$forbidden" via "${item.uri}".',
          );
        }

        if (item.uri.startsWith('../')) {
          final normalized = item.uri.replaceAll(r'\', '/');
          expect(
            normalized.contains('../presentation/') ||
                normalized.contains('../infrastructure/'),
            isFalse,
            reason:
                'Application layer violation in ${item.file.path}:${item.lineNumber}: '
                'Escapes to Presentation/Infrastructure via relative import "${item.uri}".',
          );
        }
      }
    });
  });
}
