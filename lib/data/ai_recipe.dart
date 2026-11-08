import 'package:flutter/material.dart';

/// A single Gemini-generated recipe suggestion, returned by the
/// generateRecipe Cloud Function (functions/index.js).
///
/// Distinct from ProduceItem's static `recipes`/`overripeRecipes`
/// string lists -- this is a live, generated result, so it carries
/// its own description/ingredients/steps rather than being looked up
/// in recipe_screen.dart's `_recipeDetails` map.
class AiRecipe {
  const AiRecipe({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
  });

  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  factory AiRecipe.fromMap(Map<String, dynamic> map) {
    return AiRecipe(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Untitled recipe',
      description: map['description'] as String? ?? '',
      ingredients:
          (map['ingredients'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      steps:
          (map['steps'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

/// A leafy themed UI card widget to display an [AiRecipe].
class AiRecipeCard extends StatelessWidget {
  const AiRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  final AiRecipe recipe;
  final VoidCallback? onTap;

  // Theme constants matching the botanical/leafy produce modules
  static const Color _leafPrimary = Color(0xFF2E7D32);
  static const Color _leafDark = Color(0xFF1B4D3E);
  static const Color _leafAccent = Color(0xFFA5D6A7);
  static const Color _surfaceBg = Color(0xFFF4F9F4);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _leafAccent.withValues(alpha: 0.5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLeafyHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.description.isNotEmpty) ...[
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (recipe.ingredients.isNotEmpty) ...[
                    _buildSectionHeader(
                      icon: Icons.eco_outlined,
                      title: 'Ingredients',
                    ),
                    const SizedBox(height: 8),
                    ...recipe.ingredients.map(_buildIngredientRow),
                    const SizedBox(height: 16),
                  ],
                  if (recipe.steps.isNotEmpty) ...[
                    _buildSectionHeader(
                      icon: Icons.format_list_numbered_rounded,
                      title: 'Instructions',
                    ),
                    const SizedBox(height: 8),
                    ...recipe.steps.asMap().entries.map(
                          (entry) => _buildStepRow(entry.key + 1, entry.value),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Leafy banner header with background gradient & botanical accent
  Widget _buildLeafyHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_leafDark, _leafPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // Background faint leaf accent design
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.energy_savings_leaf_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: _leafAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI SUGGESTION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _leafPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _leafDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(String ingredient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.spa,
              size: 12,
              color: _leafPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index, String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: _surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _leafAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: _leafPrimary,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}