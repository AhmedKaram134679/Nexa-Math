/// Application-wide configuration parameters.
final class AppConfiguration {
  final String applicationName;
  final String version;
  final bool isDiagnosticsEnabled;

  const AppConfiguration({
    this.applicationName = 'NexaMath',
    this.version = '1.0.0',
    this.isDiagnosticsEnabled = false,
  });

  @override
  String toString() =>
      'AppConfiguration(app: $applicationName, version: $version, diagnostics: $isDiagnosticsEnabled)';
}

/// Feature flags governing availability of platform modules and capabilities.
final class FeatureFlags {
  final bool enableExperimentalEngines;
  final bool enableExtendedPrecision;
  final bool enableSymbolicLimits;

  const FeatureFlags({
    this.enableExperimentalEngines = false,
    this.enableExtendedPrecision = true,
    this.enableSymbolicLimits = false,
  });

  @override
  String toString() =>
      'FeatureFlags(experimental: $enableExperimentalEngines, extendedPrecision: $enableExtendedPrecision)';
}
