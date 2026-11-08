import 'package:flutter/material.dart';
import '../data/ai_recipe.dart';
import '../data/ai_recipe_service.dart';
import '../data/produce_repository.dart';
import '../ml/freshness_assessor.dart';
import '../theme/app_theme.dart';

/// Recipe Screen para sa PRODUCEAIQ
///
/// Sadyang magkaiba ang trato natin sa Overripe at Rotten:
///   - Overripe: Pwede pa itong kainin o iluto (maganda pang-bake). Kaya
///     hihingi pa rin tayo ng AI recipe suggestion na babagay sa malambot na prutas.
///   - Rotten: Panis na at malamang sira. Magpapakita lang ito ng food-safety
///     warning at HINDI na tatawag ng AI para humingi ng recipe.
class RecipeScreen extends StatefulWidget {
  final String produceId;
  final FreshnessGrade? freshnessGrade;

  const RecipeScreen({super.key, this.produceId = 'mango', this.freshnessGrade});  @override
  State<RecipeScreen> createState() => _RecipeScreenState();}

class _RecipeScreenState extends State<RecipeScreen> {
  Future<List<AiRecipe>?>? _aiRecipeFuture;

  // Index ng napiling recipe sa dropdown -- laging nagsisimula sa unang
  // suggestion (index 0) bawat bagong batch ng recipes.
  int _selectedRecipeIndex = 0;

  // Callback for extension to update selected index
  void Function(int)? _onRecipeIndexChanged;

  // Madaling check kung panis na yung na-scan
  bool get _isRotten => widget.freshnessGrade == FreshnessGrade.rotten;

  // Names of every AI recipe shown so far this session (across all
  // retries), so each Retry can tell the proxy/Gemini what to avoid
  // repeating -- without this, retries kept resurfacing the same dish
  // because only the item's static curated list was ever excluded.
  final Set<String> _seenRecipeNames = {};
  bool _isRegenerating = false;
  OverlayEntry? _loadingOverlayEntry;

  @override
  void initState() {
    super.initState();    _onRecipeIndexChanged = (index) => setState(() => _selectedRecipeIndex = index);    if (!_isRotten) {
      final item = produceRepository.get(widget.produceId);      if (item != null) {
        _aiRecipeFuture = aiRecipeService.generate(
          item: item,
          freshnessGrade: widget.freshnessGrade,
          excludeRecipeNames: _seenRecipeNames.toList(),
        );      }
    }
    _isRegenerating = false;
  }

  // Function para i-refresh o subukang muli ang pag-generate ng AI recipe
  Future<void> _regenerate() async {
    final item = produceRepository.get(widget.produceId);    if (item == null || _isRotten) return;

    // Fold the batch that's currently showing (if any) into the seen
    // set before firing off the next request, so it gets excluded too.
    final currentFuture = _aiRecipeFuture;
    if (currentFuture != null) {
      final current = await currentFuture;
      if (current != null) {
        _seenRecipeNames.addAll(current.map((r) => r.name));      }
    }

    if (!mounted) return;

    // Show full-screen loading screen (old behavior - "may take a few seconds")
    _showLoadingOverlay();    final newFuture = aiRecipeService.generate(
      item: item,
      freshnessGrade: widget.freshnessGrade,
      excludeRecipeNames: _seenRecipeNames.toList(),
    );    final result = await newFuture;

    if (!mounted) return;

    setState(() {
      _isRegenerating = false;
      _selectedRecipeIndex = 0;
      _aiRecipeFuture = Future.value(result);    });    _hideLoadingOverlay();  }

  void _showLoadingOverlay() {
    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF0D7A6F),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hinihingi na sa AI ang bagong resipe...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Maaring kailanganin ng ilang segundo.\nPakiusap maghintay.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );    Overlay.of(context).insert(_loadingOverlayEntry!);  }

  void _hideLoadingOverlay() {
    _loadingOverlayEntry?.remove();    _loadingOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final item = produceRepository.get(widget.produceId);    final isOverripe = widget.freshnessGrade == FreshnessGrade.overripe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same translucent-header-over-leafy-background treatment used by
    // HomeScreen and HowItWorksScreen, so this screen doesn't look like
    // a visually different module bolted onto the rest of the app.
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF091F15).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        centerTitle: true,
        iconTheme: IconThemeData(color: MarketPalette.textPrimary(context)),
        title: Text(
          'Mungkahing Resipe ng AI',
          style: AppText.display(size: 18, color: MarketPalette.textPrimary(context)),
        ),
      ),
      body: _LeafyBackground(
        isDark: isDark,
        child: SafeArea(
          child: item == null
              ? Center(
                  child: Text(
                    'Walang nahanap na impormasyon para sa "${widget.produceId}"',
                    style: TextStyle(color: MarketPalette.textBody(context)),
                  ),
                )
              : _RecipeScreenStateCallback(
                  onChanged: _onRecipeIndexChanged!,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Ingredient context card -- laging ipinapakita (Malinis na
                      // pagkilala sa ini-scan na prutas bago ang recipe)
                      _buildContextCard(context, item),
                      const SizedBox(height: 16),
                      if (_isRotten)
                        _buildRottenWarning()
                      else ...[
                        if (isOverripe) ...[
                          _buildOverripeNotice(),
                          const SizedBox(height: 20),
                        ],
                        // AI Recipe section
                        _buildAiRecipeSection(context),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );  }

  // Label at kulay ng freshness grade chip
  (String, Color) _gradeChip() {
    switch (widget.freshnessGrade) {
      case FreshnessGrade.unripe:
        return ('Hilaw pa', AppColors.gradeUnripe);      case FreshnessGrade.ripe:
        return ('Hinog na', AppColors.gradeRipe);      case FreshnessGrade.overripe:
        return ('Sobrang hinog na', AppColors.gradeOverripe);      case FreshnessGrade.rotten:
        return ('Panis na', AppColors.gradeRotten);      default:
        return ('', AppColors.limeAccent);    }
  }

  // ════════════════════════════════════════════════════════════════
    // Ingredient context card: leaf icon | common name + scientific name | grade chip
    // ════════════════════════════════════════════════════════════════
    Widget _buildContextCard(BuildContext context, item) {
          final (gradeLabel, gradeColor) = _gradeChip();
          // Icon circle color matches freshness grade for quick visual recognition
          final iconBgColor = gradeColor.withValues(alpha: 0.18);
          final iconColor = gradeColor;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEAF5EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gradeColor.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Row(
          children: [
            // Leaf icon in a circle colored by freshness grade
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco_rounded,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Pangalan + scientific name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.commonName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: MarketPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.scientificName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: MarketPalette.textBody(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Freshness grade chip
            if (gradeLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor, width: 1.4),
                ),
                child: Text(
                  gradeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: gradeColor,
                  ),
                ),
              ),
          ],
        ),
      );  }

  // Warning kapag panis na ang na-scan (Rotten)
  Widget _buildRottenWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Soft red background para hindi masakit sa mata
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 56),
          const SizedBox(height: 16),
          const Text(
            'Hindi Ligtas Kainin',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mukhang panis o sira na ang prutas/gulay na ito. Para sa iyong kaligtasan, walang ibibigay na recipe ang AI. Mas mabuting itapon na lamang ito.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB91C1C),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );  }

  // Paalala kung ang item ay overripe
  Widget _buildOverripeNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gradeOverripe.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gradeOverripe.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.gradeOverripe),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Medyo hinog na (overripe) ito. Bagay na bagay ito para sa mga baking o smoothies!',
              style: TextStyle(color: AppColors.gradeOverripe, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );  }

  // ════════════════════════════════════════════════════════════════
    // Offline/Local recipes section — shows only recipes matching current freshness grade
    // ════════════════════════════════════════════════════════════════
  Widget _buildAiRecipeSection(BuildContext context) {
    if (_aiRecipeFuture == null) return const SizedBox.shrink();    final item = produceRepository.get(widget.produceId);    if (item == null) return const SizedBox.shrink();    // Local curated recipes available immediately
    final localRecipes = <_LocalRecipe>[
      if (widget.freshnessGrade == FreshnessGrade.overripe)
        ...item.overripeRecipes.map((n) => _LocalRecipe(name: n, source: 'overripe')),
      ...item.recipes.map((n) => _LocalRecipe(name: n, source: 'curated')),
    ];

    // Only show local recipes if we have any; otherwise wait for AI
    final hasLocal = localRecipes.isNotEmpty;

    return FutureBuilder<List<AiRecipe>?>(
      future: _aiRecipeFuture,
      builder: (context, snapshot) {
        final aiLoading = snapshot.connectionState != ConnectionState.done;
        final aiRecipes = snapshot.data;
        final aiFailed = !aiLoading && (aiRecipes == null || aiRecipes.isEmpty);        final aiSucceeded = !aiLoading && aiRecipes != null && aiRecipes.isNotEmpty;

        // Determine what to show:
        // - If AI succeeded → show AI recipes (best quality)
        // - If AI failed/loading and we have local → show local recipes
        // - If AI loading and no local → show loading
        // - If AI failed and no local → show error
        final showLoading = aiLoading && !hasLocal && !_isRegenerating;
        final showError = aiFailed && !hasLocal;
        // Show subtle loading indicator when AI is loading but local recipes are displayed
        final showAiLoadingOverlay = aiLoading && hasLocal && !_isRegenerating;

        if (showLoading) {
          return _buildLoadingCard(context);        }

        if (showError) {
          return _buildErrorCard(context);        }

        // Success: AI recipes (preferred) OR local recipes (fallback)
        final recipesToShow = aiSucceeded
            ? aiRecipes.map((r) => _DisplayRecipe.fromAi(r)).toList()
            : localRecipes.map((r) => _DisplayRecipe.fromLocal(r)).toList();        // Guard selected index
        final selectedIndex = _selectedRecipeIndex.clamp(0, recipesToShow.length - 1);        final recipe = recipesToShow[selectedIndex];

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Source indicator
                if (recipesToShow.isNotEmpty)
                  _buildSourceBadge(
                    context,
                    isAi: aiSucceeded,
                    count: recipesToShow.length,
                  ),
                const SizedBox(height: 8),
                // Recipe picker
                if (recipesToShow.length > 1) ...[
                  _buildRecipePicker(context, recipesToShow, selectedIndex),
                  const SizedBox(height: 16),
                ],
                // Main recipe card
                _buildRecipeCard(context, recipe),
                const SizedBox(height: 24),
                // Regenerate button (only for AI)
                if (aiSucceeded || aiLoading || aiFailed)
                  _buildRegenerateButton(context),
              ],
            ),
            // Subtle loading overlay when AI is still loading but local recipes shown
            if (showAiLoadingOverlay)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: Center(
                                  child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.limeAccent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Naglo-load ng AI recipes...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );      },
    );  }

  // ═══════════════════════════════════════════════════════════════
  // Main recipe card -- sumusunod sa orihinal na referensyang disenyo
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecipeCard(BuildContext context, _DisplayRecipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10281C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "AI GENERATED RECIPE" tag ──
          if (recipe.isAi)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 13, color: Color(0xFFA5D6A7)),
                    SizedBox(width: 6),
                    Text(
                      'AI GENERATED RECIPE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Recipe title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              recipe.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
                height: 1.2,
              ),
            ),
          ),

          // ── Description ──
          if (recipe.description != null && recipe.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                recipe.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: MarketPalette.textBody(context),
                  height: 1.45,
                ),
              ),
            ),

          // ── Mga Sangkap (Ingredients) ──
          if (recipe.ingredients.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded,
                      size: 19, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text(
                    'Mga Sangkap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recipe.ingredients.map((i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 5, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            i,
                            style: TextStyle(
                              fontSize: 14,
                              color: MarketPalette.textPrimary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );                }).toList(),
              ),
            ),
          ] else if (!recipe.isAi) ...[
            // Local recipe - show placeholder when ingredients not available
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded,
                      size: 19, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text(
                    'Mga Sangkap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Mga sangkap ay lalabas kapag AI-generated ang resipe.\nGamitin ang "Humingi ng ibang resipe (AI)" para sa tumpak na lista.',
                style: TextStyle(
                  fontSize: 13,
                  color: MarketPalette.textMuted(context),
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // ── Mga Hakbang sa Pagluluto (Steps) ──
          if (recipe.steps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded,
                      size: 19, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text(
                    'Mga Hakbang sa Pagluluto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: recipe.steps.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numbered green circle
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: MarketPalette.textPrimary(context),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );                }).toList(),
              ),
            ),
          ],

          // Fallback for local recipes - steps not available
          if (!recipe.isAi && recipe.steps.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded,
                      size: 19, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  const Text(
                    'Mga Hakbang sa Pagluluto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Mga hakbang ay lalabas kapag AI-generated ang resipe.\nGamitin ang "Humingi ng ibang resipe (AI)" para sa tumpak na gabay.',
                style: TextStyle(
                  fontSize: 13,
                  color: MarketPalette.textMuted(context),
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Fallback kung walang laman ang recipe (hindi dapat mangyari)
          if (recipe.ingredients.isEmpty && recipe.steps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Walang nakuhang detalye para sa recipe na ito.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );  }

  // ═══════════════════════════════════════════════════════════════
  // Full-width teal "Humingi ng ibang resipe (AI)" button
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRegenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D7A6F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _regenerate,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'HUMINGI NG IBANG RESIPE (AI)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );  }

  // Helper decoration para sa mga cards natin para pare-pareho at malinis ang itsura
  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: MarketPalette.surface(context),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );  }
}

// ── Local/AI recipe unification helpers (top-level, not nested) ──

class _LocalRecipe {
  final String name;
  final String source; // 'curated' or 'overripe'
  const _LocalRecipe({required this.name, required this.source});}

class _DisplayRecipe {
  final String name;
  final String? description;
  final List<String> ingredients;
  final List<String> steps;
  final bool isAi;

  _DisplayRecipe._({
    required this.name,
    this.description,
    required this.ingredients,
    required this.steps,
    required this.isAi,
  });  factory _DisplayRecipe.fromAi(AiRecipe recipe) => _DisplayRecipe._(
    name: recipe.name,
    description: recipe.description,
    ingredients: recipe.ingredients,
    steps: recipe.steps,
    isAi: true,
  );  factory _DisplayRecipe.fromLocal(_LocalRecipe local) => _DisplayRecipe._(
    name: local.name,
    description: local.source == 'overripe'
        ? 'Tradisyonal na pagluluto para sa sobrang hinog na ${local.name.toLowerCase()}'
        : 'Kilalang resipe para sa ${local.name.toLowerCase()}',
    ingredients: const [],
    steps: const [],
    isAi: false,
  );}

// Extension on _RecipeScreenState for the new helper widgets
extension _RecipeScreenStateHelpers on _RecipeScreenState {
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: _cardDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.limeAccent),
          const SizedBox(height: 24),
          Text(
            'Bumubuo ng mga masarap na recipe...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MarketPalette.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Maaaring tumagal ito ng ilang segundo. Maaring maghintay.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: MarketPalette.textBody(context)),
          ),
        ],
      ),
    );  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: MarketPalette.textBody(context)),
          const SizedBox(height: 16),
          Text(
            'Oops! Nabigo ang AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MarketPalette.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hindi kami makapag-generate ng recipe sa ngayon. Maaaring mahina ang internet connection o may problema sa AI server.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: MarketPalette.textBody(context), height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'SUBUKAN MULI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );  }

  Widget _buildSourceBadge(BuildContext context, {required bool isAi, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAi
            ? const Color(0xFF1B5E20).withValues(alpha: 0.15)
            : AppColors.limeAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAi
              ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
              : AppColors.limeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAi ? Icons.auto_awesome_rounded : Icons.eco_rounded,
            size: 14,
            color: isAi ? const Color(0xFF1B5E20) : AppColors.limeAccent,
          ),
          const SizedBox(width: 6),
          Text(
            isAi
                ? '$count na AI-generated na mungkahi'
                : '$count na lokal na resipe (offline available)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAi ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );  }

  Widget _buildRecipePicker(BuildContext context, List<_DisplayRecipe> recipes, int selectedIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pumili ng recipe (${recipes.length} mga mungkahi)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MarketPalette.textBody(context),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: MarketPalette.surfaceAlt(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MarketPalette.divider(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded),
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MarketPalette.textPrimary(context),
              ),
              items: [
                for (var i = 0; i < recipes.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      recipes[i].name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                // Use a callback since we can't call setState from extension
                (_RecipeScreenStateCallback.of(context))(value);              },
            ),
          ),
        ),
      ],
    );  }
}

/// Callback for extension to update recipe index
class _RecipeScreenStateCallback extends InheritedWidget {
  final void Function(int) onChanged;

  const _RecipeScreenStateCallback({
    required this.onChanged,
    required super.child,
  });  static void Function(int) of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_RecipeScreenStateCallback>();    return widget?.onChanged ?? (_) {};
  }

  @override
  bool updateShouldNotify(_RecipeScreenStateCallback oldWidget) => true;
}

/// Custom Background Wrapper with Botanical Gradient & Organic Leaf Painter.
class _LeafyBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _LeafyBackground({
    required this.isDark,
    required this.child,
  });  @override
  Widget build(BuildContext context) {
    // Rich forest dark green gradient tuned so leaves pop sharply
    final gradientColors = isDark
        ? const [
            Color(0xFF091F15), // Deep forest pine
            Color(0xFF05170F),
            Color(0xFF020C07),
          ]
        : const [
            Color(0xFFEAF5EC), // Soft botanical leaf green
            Color(0xFFDBEFE1),
            Color(0xFFCCE8D4),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: CustomPaint(
        painter: _LeafPatternPainter(isDark: isDark),
        child: child,
      ),
    );  }
}

/// Custom Vector Painter to draw ambient, clearly visible leaves in both modes
class _LeafPatternPainter extends CustomPainter {
  final bool isDark;

  _LeafPatternPainter({required this.isDark});  @override
  void paint(Canvas canvas, Size size) {
    // Fill paint with higher visibility in Dark Mode
    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.18) // Bright emerald mint fill
          : const Color(0xFF059669).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Glowing contour stroke paint specifically for Dark Mode crispness
    final strokePaint = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.28) // Subtle mint contour line
          : const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Decorative background leaf 1 (Top Right)
    final path1 = Path();    path1.moveTo(size.width * 0.72, 0);    path1.quadraticBezierTo(
        size.width, size.height * 0.08, size.width, size.height * 0.22);    path1.quadraticBezierTo(
        size.width * 0.62, size.height * 0.18, size.width * 0.72, 0);    path1.close();    canvas.drawPath(path1, fillPaint);    canvas.drawPath(path1, strokePaint);    // Decorative background leaf 2 (Middle Left)
    final path2 = Path();    path2.moveTo(0, size.height * 0.42);    path2.quadraticBezierTo(
        size.width * 0.38, size.height * 0.46, size.width * 0.28, size.height * 0.60);    path2.quadraticBezierTo(
        size.width * 0.05, size.height * 0.56, 0, size.height * 0.42);    path2.close();    canvas.drawPath(path2, fillPaint);    canvas.drawPath(path2, strokePaint);    // Decorative background leaf 3 (Bottom Right)
    final path3 = Path();    path3.moveTo(size.width, size.height * 0.70);    path3.quadraticBezierTo(
        size.width * 0.65, size.height * 0.80, size.width * 0.78, size.height * 0.94);    path3.quadraticBezierTo(
        size.width * 0.95, size.height * 0.86, size.width, size.height * 0.70);    path3.close();    canvas.drawPath(path3, fillPaint);    canvas.drawPath(path3, strokePaint);  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}