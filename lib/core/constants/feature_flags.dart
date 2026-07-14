/// Temporary UI toggles — flip back when the underlying feature is ready.
class FeatureFlags {
  /// Payments aren't live yet (see PaymentComingSoonScreen), so course price
  /// tags are hidden across the student and instructor UI until checkout
  /// ships. Instructors can still set a price when creating a course.
  static const bool showCoursePricing = false;
}
