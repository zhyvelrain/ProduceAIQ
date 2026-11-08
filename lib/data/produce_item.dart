// Model natin
class ProduceItem {
  final String id;
  final String commonName;
  final String scientificName;
  final String category; // "fruit" or "vegetable"

  // Botanical family (e.g. "Cucurbitaceae"), distinct from cultivar-level
  // variety within a single species (e.g. sitaw vs. bagyo beans, both
  // Vigna unguiculata subsp. sesquipedalis).
  // Assigned by an admin during review when new items are added (submission_service.dart)
  final String family;

  // Short produce history/background -- Thesis Ch.1 Module 1 and Fig 3.4
  // both specify that the Result Screen surfaces produce history
  // alongside the common/scientific name, not just the name itself.
  final String history;

  // Estimated shelf life under typical Philippine market conditions --
  // Thesis Ch.3 Module 2 ("the module also presents the estimated shelf
  // life or life span of the identified produce").
  final String shelfLife;

  final Map<String, dynamic> nutrition;
  final List<String> recipes;

  // Recipes specifically suited to overripe/softened produce -- Thesis
  // Ch.3 Module 4: "prioritizing recipes designed for overripe or
  // softened produce" once FreshnessAssessor grades an item Overripe.
  // Empty for items where an "overripe use" isn't really a distinct
  // recipe category (e.g. leafy greens).
  final List<String> overripeRecipes;

  // Short visual identification cues (shape, color, texture) used by
  // DisambiguationScreen's "Show Me the Difference" comparison view --
  // Thesis Fig 3.6. Text-based rather than reference photos, since no
  // curated lookalike image set exists in dataset/.
  final String visualIdTips;

  // Name equivalents in other languages. Thesis Fig 3.4's worked example
  // for Mango explicitly lists Filipino, Spanish, Malay, Indonesian,
  // Chinese, and Japanese -- so "spanish" is included per-item, not just
  // for Mango.
  final Map<String, String> translations;

  // Convenience getter used in UI code that expects a single `name`
  // property. Returns `commonName`.
  String get name => commonName;

  const ProduceItem({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.family,
    this.history = '',
    this.shelfLife = '',
    required this.nutrition,
    this.recipes = const [],
    this.overripeRecipes = const [],
    this.visualIdTips = '',
    this.translations = const {},
  });
}
