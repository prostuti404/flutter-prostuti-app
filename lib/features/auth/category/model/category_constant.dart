// category_constant.dart
//
// The main student categories the backend has always accepted.
//
// `GET /auth/registration-categories` is now the source of truth for what the
// picker shows (main categories plus their sub-categories — see
// `RegistrationCategory`). These constants remain for two jobs: mapping a wire
// value to its localized label and icon, and as the offline fallback when that
// endpoint cannot be reached.

class MainCategory {
  static const String ACADEMIC = "Academic";
  static const String ADMISSION = "Admission";
  static const String JOB = "Job";

  static const List<String> values = [ACADEMIC, ADMISSION, JOB];
}
