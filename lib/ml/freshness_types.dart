/// Result of a freshness assessment: Unripe, Ripe (peak eating
/// condition), Overripe, or Rotten.
///
/// Overripe vs Rotten is a deliberate, meaningful distinction, not
/// just two words for "old": Overripe means very soft/spotted but
/// STILL EDIBLE -- great for baking/cooking (spotty banana for banana
/// bread) even if not ideal eaten raw. Rotten means actually
/// spoiled -- moldy, foul, should be discarded. Recipe suggestions
/// are shown for Overripe; a food-safety warning (no recipes) is
/// shown for Rotten. Conflating these two would mean either
/// recommending recipes for spoiled food, or unnecessarily telling
/// someone to throw away food that's still perfectly cookable --
/// see dataset_freshness/README.txt for the same distinction as it
/// applies to collecting training photos.
///
/// Shared between freshness_assessor.dart (which can produce this via
/// either a real trained model or a heuristic fallback) and
/// freshness_classifier.dart (the real trained-model path) -- kept in
/// its own file so those two don't need to import each other.
enum FreshnessGrade {
  unripe,
  ripe,
  overripe,
  rotten,
}

extension FreshnessGradeLabel on FreshnessGrade {
  String get label {
    switch (this) {
      case FreshnessGrade.unripe:
        return 'Unripe';
      case FreshnessGrade.ripe:
        return 'Ripe';
      case FreshnessGrade.overripe:
        return 'Overripe';
      case FreshnessGrade.rotten:
        return 'Rotten';
    }
  }
}
