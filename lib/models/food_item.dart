class FoodItem {
  final String name;
  final String emoji;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String serving;
  final String category;

  const FoodItem({
    required this.name, required this.emoji, required this.calories,
    required this.protein, required this.carbs, required this.fat,
    required this.serving, required this.category,
  });
}

class Exercise {
  final String name;
  final String emoji;
  final String category;
  final int caloriesBurned;
  final String duration;
  final List<String> muscleGroups;
  final List<String> steps;
  final String difficulty;

  const Exercise({
    required this.name, required this.emoji, required this.category,
    required this.caloriesBurned, required this.duration,
    required this.muscleGroups, required this.steps, required this.difficulty,
  });
}

class Recipe {
  final String name;
  final String emoji;
  final List<String> ingredients;
  final int calories;
  final int protein;
  final String cookTime;
  final String difficulty;
  final String description;
  final List<String> steps;

  const Recipe({
    required this.name, required this.emoji, required this.ingredients,
    required this.calories, required this.protein, required this.cookTime,
    required this.difficulty, required this.description, required this.steps,
  });
}
