import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/recipe_data.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────── Model ───────────────────────────

class AiRecipe {
  final String name;
  final String emoji;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String cookTime;
  final String difficulty;
  final String cuisine;
  // Lowercase keywords used for ingredient-based filtering
  final List<String> keywords;

  const AiRecipe({
    required this.name,
    required this.emoji,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.cookTime,
    required this.difficulty,
    required this.cuisine,
    this.keywords = const [],
  });

  factory AiRecipe.fromJson(Map<String, dynamic> j) => AiRecipe(
        name: j['name'] ?? 'Recipe',
        emoji: j['emoji'] ?? '🍽',
        description: j['description'] ?? '',
        ingredients: List<String>.from(j['ingredients'] ?? []),
        steps: List<String>.from(j['steps'] ?? []),
        calories: (j['calories'] ?? 0) as int,
        protein: (j['protein'] ?? 0) as int,
        carbs: (j['carbs'] ?? 0) as int,
        fat: (j['fat'] ?? 0) as int,
        cookTime: j['cookTime'] ?? '30 min',
        difficulty: j['difficulty'] ?? 'Medium',
        cuisine: j['cuisine'] ?? 'Indian',
      );

  /// How many of [selected] ingredients match this recipe's keywords.
  int matchCount(List<String> selected) {
    int count = 0;
    for (final sel in selected) {
      final s = sel.toLowerCase();
      if (keywords.any((k) => k.contains(s) || s.contains(k))) count++;
    }
    return count;
  }
}

// ─────────────────────────── Main Screen ───────────────────────────

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final List<String> _ingredients = [];
  List<AiRecipe>? _recipes;
  final bool _loading = false;
  String? _error;
  late AnimationController _shimmerCtrl;

  // Region filter: null = All
  String? _regionFilter;
  String _userCountry = 'India';

  List<String> get _suggestions => _suggestionsForCountry(_userCountry);

  static List<String> _suggestionsForCountry(String country) {
    switch (country) {
      case 'USA': case 'Canada': case 'Australia': case 'New Zealand':
        return ['Chicken', 'Beef', 'Salmon', 'Eggs', 'Avocado', 'Cheese',
                'Broccoli', 'Potato', 'Oats', 'Berries', 'Garlic', 'Tomato'];
      case 'UK':
        return ['Chicken', 'Beef', 'Cod', 'Eggs', 'Potato', 'Mushroom',
                'Peas', 'Beans', 'Onion', 'Cheese', 'Lamb', 'Carrot'];
      case 'Saudi Arabia': case 'UAE': case 'Lebanon': case 'Egypt': case 'Turkey':
        return ['Chicken', 'Lamb', 'Chickpeas', 'Tahini', 'Tomato', 'Onion',
                'Garlic', 'Parsley', 'Lemon', 'Pita', 'Eggplant', 'Cumin'];
      case 'Japan':
        return ['Salmon', 'Tofu', 'Miso', 'Rice', 'Soy Sauce', 'Nori',
                'Egg', 'Mushroom', 'Spring Onion', 'Sesame', 'Dashi', 'Mirin'];
      case 'China':
        return ['Chicken', 'Rice', 'Soy Sauce', 'Garlic', 'Ginger', 'Egg',
                'Tofu', 'Bok Choy', 'Sesame Oil', 'Spring Onion', 'Oyster Sauce', 'Pork'];
      case 'South Korea':
        return ['Beef', 'Kimchi', 'Rice', 'Gochujang', 'Sesame', 'Egg',
                'Spinach', 'Carrot', 'Soy Sauce', 'Garlic', 'Spring Onion', 'Tofu'];
      case 'Thailand': case 'Vietnam': case 'Indonesia': case 'Malaysia':
      case 'Philippines': case 'Singapore':
        return ['Chicken', 'Rice', 'Fish Sauce', 'Lemongrass', 'Coconut Milk',
                'Chilli', 'Lime', 'Garlic', 'Prawn', 'Ginger', 'Coriander', 'Basil'];
      case 'Italy': case 'France': case 'Spain': case 'Greece': case 'Portugal':
        return ['Pasta', 'Tomato', 'Olive Oil', 'Garlic', 'Onion', 'Parmesan',
                'Basil', 'Lemon', 'Chicken', 'Beef', 'Mozzarella', 'Egg'];
      case 'Mexico': case 'Brazil': case 'Argentina': case 'Colombia': case 'Peru':
        return ['Chicken', 'Beef', 'Tortilla', 'Avocado', 'Tomato', 'Onion',
                'Lime', 'Coriander', 'Chilli', 'Rice', 'Beans', 'Corn'];
      case 'Nigeria': case 'Ethiopia': case 'South Africa':
        return ['Chicken', 'Beef', 'Rice', 'Tomato', 'Onion', 'Palm Oil',
                'Chilli', 'Coriander', 'Garlic', 'Ginger', 'Peanuts', 'Spinach'];
      case 'Germany': case 'Russia': case 'Poland':
        return ['Pork', 'Beef', 'Potato', 'Onion', 'Mushroom', 'Sauerkraut',
                'Beetroot', 'Carrot', 'Butter', 'Sour Cream', 'Cabbage', 'Egg'];
      case 'Pakistan': case 'Bangladesh':
        return ['Chicken', 'Beef', 'Mutton', 'Rice', 'Onion', 'Tomato',
                'Garlic', 'Ginger', 'Chilli', 'Coriander', 'Yogurt', 'Ghee'];
      default: // India and South Asian
        return ['Chicken', 'Rice', 'Paneer', 'Eggs', 'Tomato', 'Onion',
                'Dal', 'Potato', 'Spinach', 'Coconut', 'Lemon', 'Oats',
                'Fish', 'Yogurt', 'Garlic', 'Ginger'];
    }
  }

  static List<({String label, String? value})> _regionsForCountry(String country) {
    switch (country) {
      case 'India': case 'Sri Lanka': case 'Nepal':
        return [(label: 'All', value: null), (label: '🌶 North Indian', value: 'North Indian'),
                (label: '🥥 South Indian', value: 'South Indian'), (label: '🍃 Healthy', value: 'Indian')];
      case 'Pakistan': case 'Bangladesh':
        return [(label: 'All', value: null), (label: '🍛 South Asian', value: 'South Asian'),
                (label: '🌶 North Indian', value: 'North Indian'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'USA': case 'Canada': case 'Australia': case 'New Zealand':
        return [(label: 'All', value: null), (label: '🍔 American', value: 'American'),
                (label: '🌮 Mexican', value: 'Mexican'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'UK':
        return [(label: 'All', value: null), (label: '🇬🇧 British', value: 'British'),
                (label: '🍝 Mediterranean', value: 'Mediterranean'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'Saudi Arabia': case 'UAE': case 'Lebanon': case 'Egypt': case 'Turkey':
        return [(label: 'All', value: null), (label: '🧆 Middle Eastern', value: 'Middle Eastern'),
                (label: '🍝 Mediterranean', value: 'Mediterranean'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'Japan': case 'China': case 'South Korea':
      case 'Thailand': case 'Vietnam': case 'Indonesia':
      case 'Malaysia': case 'Philippines': case 'Singapore':
        return [(label: 'All', value: null), (label: '🥢 East Asian', value: 'East Asian'),
                (label: '🍃 Healthy', value: 'Healthy'), (label: '🍔 Western', value: 'American')];
      case 'Italy': case 'France': case 'Spain': case 'Greece': case 'Portugal':
        return [(label: 'All', value: null), (label: '🍝 Mediterranean', value: 'Mediterranean'),
                (label: '🧆 Middle Eastern', value: 'Middle Eastern'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'Mexico': case 'Brazil': case 'Argentina': case 'Colombia': case 'Peru':
        return [(label: 'All', value: null), (label: '🌮 Latin American', value: 'Mexican'),
                (label: '🍔 American', value: 'American'), (label: '🍃 Healthy', value: 'Healthy')];
      case 'Nigeria': case 'Ethiopia': case 'South Africa':
        return [(label: 'All', value: null), (label: '🫕 African', value: 'African'),
                (label: '🍃 Healthy', value: 'Healthy'), (label: '🍔 Western', value: 'American')];
      case 'Germany': case 'Russia': case 'Poland':
        return [(label: 'All', value: null), (label: '🥩 European', value: 'European'),
                (label: '🍝 Mediterranean', value: 'Mediterranean'), (label: '🍃 Healthy', value: 'Healthy')];
      default:
        return [(label: 'All', value: null), (label: '🍃 Healthy', value: 'Healthy'),
                (label: '🌶 Indian', value: 'North Indian'), (label: '🍝 Mediterranean', value: 'Mediterranean')];
    }
  }

  static String? _defaultRegionForCountry(String country) {
    switch (country) {
      case 'India': case 'Sri Lanka': case 'Nepal': return 'North Indian';
      case 'Pakistan': case 'Bangladesh': return 'South Asian';
      case 'USA': case 'Canada': case 'Australia': case 'New Zealand': return 'American';
      case 'UK': return 'British';
      case 'Saudi Arabia': case 'UAE': case 'Lebanon': case 'Egypt': case 'Turkey': return 'Middle Eastern';
      case 'Japan': case 'China': case 'South Korea':
      case 'Thailand': case 'Vietnam': case 'Indonesia':
      case 'Malaysia': case 'Philippines': case 'Singapore': return 'East Asian';
      case 'Italy': case 'France': case 'Spain': case 'Greece': case 'Portugal': return 'Mediterranean';
      case 'Mexico': case 'Brazil': case 'Argentina': case 'Colombia': case 'Peru': return 'Mexican';
      case 'Nigeria': case 'Ethiopia': case 'South Africa': return 'African';
      case 'Germany': case 'Russia': case 'Poland': return 'European';
      default: return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    final country = Provider.of<AuthProvider>(context, listen: false).currentUser?.country ?? 'India';
    _userCountry = country;
    _regionFilter = _defaultRegionForCountry(country);
    // Seed the initial recipe list directly — no setState in initState
    var pool = List<AiRecipe>.from(kAllRecipes);
    if (_regionFilter != null) {
      pool = pool.where((r) => r.cuisine == _regionFilter).toList();
    }
    _recipes = pool;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _addIngredient(String ing) {
    final trimmed = ing.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    if (_ingredients.any((i) => i.toLowerCase() == normalized.toLowerCase())) return;
    if (_ingredients.length >= 12) {
      _showSnack('Max 12 ingredients allowed');
      return;
    }
    setState(() {
      _ingredients.add(normalized);
      _searchCtrl.clear();
    });
    _filterRecipes();
  }

  void _removeIngredient(String ing) {
    setState(() {
      _ingredients.remove(ing);
    });
    _filterRecipes();
  }

  void _filterRecipes() {
    _searchFocus.unfocus();
    var pool = List<AiRecipe>.from(kAllRecipes);

    // Apply region filter
    if (_regionFilter != null) {
      pool = pool.where((r) => r.cuisine == _regionFilter).toList();
    }

    if (_ingredients.isEmpty) {
      setState(() => _recipes = pool);
      return;
    }

    // Score and filter by ingredient match
    final scored = pool
        .map((r) => (recipe: r, score: r.matchCount(_ingredients)))
        .where((e) => e.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    setState(() => _recipes = scored.map((e) => e.recipe).toList());
  }

  void _setRegion(String? region) {
    setState(() => _regionFilter = region);
    _filterRecipes();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  bool _showIngredientSearch = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cuisine filter tabs ─────────────────────────────
                  _buildGenerateButton(isDark),
                  const SizedBox(height: 16),
                  // ── Ingredient filter toggle ────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showIngredientSearch = !_showIngredientSearch),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _ingredients.isNotEmpty
                            ? AppColors.primary.withOpacity(0.1)
                            : (isDark ? AppColors.surfaceDark : AppColors.surface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ingredients.isNotEmpty
                              ? AppColors.primary.withOpacity(0.4)
                              : (isDark ? AppColors.borderDark : AppColors.border),
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.tune_rounded,
                            size: 18,
                            color: _ingredients.isNotEmpty ? AppColors.primary : AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ingredients.isEmpty
                                ? 'Filter by ingredients in your kitchen'
                                : '${_ingredients.length} ingredient${_ingredients.length > 1 ? 's' : ''} filtering recipes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _ingredients.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: _ingredients.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          _showIngredientSearch ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ]),
                    ),
                  ),
                  if (_showIngredientSearch) ...[
                    const SizedBox(height: 12),
                    _buildSearchBar(isDark),
                    const SizedBox(height: 12),
                    if (_ingredients.isNotEmpty) ...[
                      _buildIngredientChips(isDark),
                      const SizedBox(height: 12),
                    ] else ...[
                      _buildSuggestions(isDark),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 12),
                  // ── Recipe list ─────────────────────────────────────
                  if (_loading) _buildSkeletons(isDark),
                  if (_error != null) _buildError(isDark),
                  if (_recipes != null && !_loading) _buildResults(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipes 🍽',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            Text(
              'Tap any recipe to see how to cook it',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type an ingredient…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: _addIngredient,
            ),
          ),
          GestureDetector(
            onTap: () => _addIngredient(_searchCtrl.text),
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => _addIngredient(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientChips(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your ingredients',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                _ingredients.clear();
                _recipes = null;
                _error = null;
              }),
              child: Text(
                'Clear all',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ingredients.map((ing) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Chip(
                label: Text(
                  ing,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                onDeleted: () => _removeIngredient(ing),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          '${_ingredients.length}/12 ingredients',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        // Also show quick-add for remaining suggestions
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _suggestions
              .where((s) => !_ingredients.any((i) => i.toLowerCase() == s.toLowerCase()))
              .take(8)
              .map((s) => GestureDetector(
                    onTap: () => _addIngredient(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            s,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    final regions = _regionsForCountry(_userCountry);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: regions.map((r) {
          final active = _regionFilter == r.value;
          return GestureDetector(
            onTap: () => _setRegion(r.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.brandGreen : (isDark ? AppColors.surfaceDark : AppColors.surface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.brandGreen : (isDark ? AppColors.borderDark : AppColors.border),
                ),
              ),
              child: Text(
                r.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkeletons(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✨ AI is crafting recipes for you…',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (i) => _SkeletonCard(isDark: isDark, ctrl: _shimmerCtrl)),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _filterRecipes,
                  child: Text(
                    'Tap to retry',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_recipes!.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('🫙', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No matching recipes',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Try different ingredients or change the region filter',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🍽', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              _ingredients.isEmpty
                  ? '${_recipes!.length} recipes'
                  : '${_recipes!.length} matching recipes',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recipes!.asMap().entries.map((e) => _RecipeCard(
              recipe: e.value,
              isDark: isDark,
              index: e.key,
              matchCount: _ingredients.isEmpty ? -1 : e.value.matchCount(_ingredients),
            )),
      ],
    );
  }
}

// ─────────────────────────── Recipe Card ───────────────────────────

class _RecipeCard extends StatelessWidget {
  final AiRecipe recipe;
  final bool isDark;
  final int index;
  // -1 = no filtering active, 0+ = number of matching ingredients
  final int matchCount;

  const _RecipeCard({
    required this.recipe,
    required this.isDark,
    required this.index,
    this.matchCount = -1,
  });

  static const _gradients = [
    [Color(0xFF4CAF50), Color(0xFF81C784)],
    [Color(0xFF2196F3), Color(0xFF64B5F6)],
    [Color(0xFFFF9800), Color(0xFFFFB74D)],
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _gradients[index % _gradients.length];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(recipe.emoji, style: const TextStyle(fontSize: 56)),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (matchCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$matchCount match${matchCount > 1 ? 'es' : ''}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.cuisine,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Macro row
                  Row(
                    children: [
                      _MacroPill(label: '🔥', value: '${recipe.calories}', sub: 'kcal', color: AppColors.accent),
                      const SizedBox(width: 6),
                      _MacroPill(label: '💪', value: '${recipe.protein}g', sub: 'protein', color: AppColors.primary),
                      const SizedBox(width: 6),
                      _MacroPill(label: '⏱', value: recipe.cookTime, sub: '', color: AppColors.amber),
                      const SizedBox(width: 6),
                      _MacroPill(label: '👨‍🍳', value: recipe.difficulty, sub: '', color: AppColors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (sub.isNotEmpty)
              Text(sub, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Skeleton Card ───────────────────────────

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  final AnimationController ctrl;
  const _SkeletonCard({required this.isDark, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final shimmerColor = isDark
            ? Color.lerp(AppColors.surfaceDark, AppColors.surfaceVariantDark, ctrl.value)!
            : Color.lerp(const Color(0xFFEEEEEE), const Color(0xFFF8F8F8), ctrl.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 200, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 8),
                    Container(height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 4),
                    Container(height: 12, width: 250, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(4, (_) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 46,
                          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(10)),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Detail Screen ───────────────────────────

class RecipeDetailScreen extends StatefulWidget {
  final AiRecipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  // Ingredients the user says they already have
  final Set<int> _haveIndices = {};

  static const _gradients = [
    [Color(0xFF4CAF50), Color(0xFF81C784)],
    [Color(0xFF2196F3), Color(0xFF64B5F6)],
    [Color(0xFFFF9800), Color(0xFFFFB74D)],
  ];

  List<String> get _missingIngredients => widget.recipe.ingredients
      .asMap()
      .entries
      .where((e) => !_haveIndices.contains(e.key))
      .map((e) => e.value)
      .toList();

  // Strips leading quantities like "500g", "1 cup", "2 tbsp" to get the food name
  String _coreName(String ing) {
    return ing
        .replaceAll(RegExp(r'^\d+[\w/]*\s+'), '')
        .replaceAll(RegExp(r'^\d+\s+'), '')
        .replaceFirst(RegExp(r'^(cup|tbsp|tsp|g|ml|kg|piece|handful|pinch)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim()
        .split(' ')
        .take(3)
        .join(' ');
  }

  Future<void> _openApp(String baseUrl, List<String> ingredients) async {
    final query = Uri.encodeComponent(ingredients.map(_coreName).join(' '));
    final uri = Uri.parse('$baseUrl$query');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open app'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final missing = _missingIngredients;
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF4CAF50),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradients[0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(recipe.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.cuisine,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Macro cards
                  Row(
                    children: [
                      _infoCard('🔥', '${recipe.calories}', 'kcal', AppColors.accentLight, AppColors.accent),
                      const SizedBox(width: 10),
                      _infoCard('💪', '${recipe.protein}g', 'protein', AppColors.primaryLight, AppColors.primary),
                      const SizedBox(width: 10),
                      _infoCard('🌾', '${recipe.carbs}g', 'carbs', AppColors.amberLight, AppColors.amber),
                      const SizedBox(width: 10),
                      _infoCard('🫒', '${recipe.fat}g', 'fat', AppColors.purpleLight, AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _tagPill('⏱ ${recipe.cookTime}'),
                      const SizedBox(width: 8),
                      _tagPill('👨‍🍳 ${recipe.difficulty}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingredients — with "I have this" toggles
                  _sectionHeader('Ingredients', '${recipe.ingredients.length} items', isDark),
                  const SizedBox(height: 6),
                  Text(
                    'Tap ingredients you already have at home',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.ingredients.asMap().entries.map((entry) {
                      final have = _haveIndices.contains(entry.key);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (have) {
                            _haveIndices.remove(entry.key);
                          } else {
                            _haveIndices.add(entry.key);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: have ? AppColors.brandGreen.withOpacity(0.15) : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: have ? AppColors.brandGreen : AppColors.primary.withOpacity(0.2),
                              width: have ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                have ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 14,
                                color: have ? AppColors.brandGreen : AppColors.primary.withOpacity(0.5),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                entry.value,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: have ? AppColors.brandGreen : AppColors.primaryDark,
                                  decoration: have ? TextDecoration.lineThrough : null,
                                  decorationColor: AppColors.brandGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_haveIndices.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.brandGreen),
                        const SizedBox(width: 4),
                        Text(
                          '${_haveIndices.length} of ${recipe.ingredients.length} ingredients available',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Order missing ingredients
                  if (missing.isNotEmpty) _buildOrderSection(missing, isDark),

                  const SizedBox(height: 24),

                  // Steps
                  _sectionHeader('Instructions', '${recipe.steps.length} steps', isDark),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String emoji, String value, String sub, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String sub, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          sub,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOrderSection(List<String> missing, bool isDark) {
    const apps = [
      (
        name: 'Blinkit',
        emoji: '💛',
        color: Color(0xFFF8CB2E),
        textColor: Color(0xFF1A1A1A),
        url: 'https://blinkit.com/s/?q=',
      ),
      (
        name: 'Zepto',
        emoji: '⚡',
        color: Color(0xFF8B2FC9),
        textColor: Colors.white,
        url: 'https://www.zeptonow.com/search?query=',
      ),
      (
        name: 'Instamart',
        emoji: '🛒',
        color: Color(0xFFFC8019),
        textColor: Colors.white,
        url: 'https://www.swiggy.com/instamart/search?query=',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFFFE0A0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${missing.length} ingredient${missing.length > 1 ? 's' : ''} needed',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order all missing ingredients via quick commerce:',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          // Missing ingredient chips (read-only preview)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: missing.map((ing) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Text(
                _coreName(ing),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 14),
          // App buttons
          Row(
            children: apps.map((app) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => _openApp(app.url, missing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: app.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(app.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          app.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: app.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Opens the app/browser — select your items and checkout',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
