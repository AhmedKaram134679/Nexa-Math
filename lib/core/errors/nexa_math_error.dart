/// Authoritative error contract for all technical and domain failures in NexaMath.
///
/// Error contracts must not contain UI-localized presentation strings.
abstract interface class NexaMathError {
  /// Machine-readable error code uniquely categorizing the failure.
  String get code;

  /// Technical, diagnostic explanation of what occurred.
  String get technicalMessage;
}
