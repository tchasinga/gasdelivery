/// Converts API values with underscores into readable UI text.
///
/// Example: `in_transit` → `in transit` (spaces, lowercase).
/// Use only for **display**; keep sending raw API strings in requests.
String formatApiLabelForUi(String? raw) {
  if (raw == null) return '—';
  final t = raw.trim();
  if (t.isEmpty) return '—';
  return t.replaceAll('_', ' ').toLowerCase();
}
