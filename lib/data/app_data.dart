import '../models/food_item.dart';

class AppData {
  static const List<FoodItem> foods = [
    FoodItem(name: 'Oats', emoji: '🥣', calories: 389, protein: 17, carbs: 66, fat: 7, serving: '100g', category: 'Breakfast'),
    FoodItem(name: 'Grilled Chicken', emoji: '🍗', calories: 165, protein: 31, carbs: 0, fat: 3.6, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Whole Egg', emoji: '🥚', calories: 77, protein: 6.3, carbs: 0.6, fat: 5.3, serving: '1 egg', category: 'Protein'),
    FoodItem(name: 'Banana', emoji: '🍌', calories: 89, protein: 1.1, carbs: 23, fat: 0.3, serving: '1 medium', category: 'Fruits'),
    FoodItem(name: 'White Rice', emoji: '🍚', calories: 130, protein: 2.7, carbs: 28, fat: 0.3, serving: '100g', category: 'Carbs'),
    FoodItem(name: 'Avocado', emoji: '🥑', calories: 120, protein: 1.5, carbs: 6, fat: 11, serving: 'half', category: 'Fats'),
    FoodItem(name: 'Salmon', emoji: '🐟', calories: 208, protein: 20, carbs: 0, fat: 13, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Broccoli', emoji: '🥦', calories: 34, protein: 2.8, carbs: 7, fat: 0.4, serving: '100g', category: 'Vegetables'),
    FoodItem(name: 'Paneer', emoji: '🧀', calories: 265, protein: 18, carbs: 3.4, fat: 20, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Almonds', emoji: '🌰', calories: 174, protein: 6, carbs: 6, fat: 15, serving: '30g', category: 'Snacks'),
    FoodItem(name: 'Whole Milk', emoji: '🥛', calories: 122, protein: 6.4, carbs: 9.5, fat: 6.4, serving: '200ml', category: 'Dairy'),
    FoodItem(name: 'Sweet Potato', emoji: '🍠', calories: 86, protein: 1.6, carbs: 20, fat: 0.1, serving: '100g', category: 'Carbs'),
    FoodItem(name: 'Lentils', emoji: '🫘', calories: 116, protein: 9, carbs: 20, fat: 0.4, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Peanut Butter', emoji: '🥜', calories: 188, protein: 8, carbs: 6, fat: 16, serving: '2 tbsp', category: 'Fats'),
    FoodItem(name: 'Whole Wheat Bread', emoji: '🍞', calories: 80, protein: 3.6, carbs: 15, fat: 1, serving: '1 slice', category: 'Carbs'),
    FoodItem(name: 'Greek Yogurt', emoji: '🧆', calories: 100, protein: 17, carbs: 6, fat: 0.7, serving: '150g', category: 'Dairy'),
    FoodItem(name: 'Brown Rice', emoji: '🌾', calories: 111, protein: 2.6, carbs: 23, fat: 0.9, serving: '100g', category: 'Carbs'),
    FoodItem(name: 'Tuna (canned)', emoji: '🐠', calories: 109, protein: 24, carbs: 0, fat: 1, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Spinach', emoji: '🥬', calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, serving: '100g', category: 'Vegetables'),
    FoodItem(name: 'Apple', emoji: '🍎', calories: 52, protein: 0.3, carbs: 14, fat: 0.2, serving: '1 medium', category: 'Fruits'),
    FoodItem(name: 'Whey Protein', emoji: '💪', calories: 120, protein: 25, carbs: 3, fat: 1.5, serving: '1 scoop', category: 'Supplements'),
    FoodItem(name: 'Cottage Cheese', emoji: '🫙', calories: 98, protein: 11, carbs: 3.4, fat: 4.5, serving: '100g', category: 'Dairy'),
    FoodItem(name: 'Chickpeas', emoji: '🟡', calories: 164, protein: 8.9, carbs: 27, fat: 2.6, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Olive Oil', emoji: '🫒', calories: 119, protein: 0, carbs: 0, fat: 13.5, serving: '1 tbsp', category: 'Fats'),
    FoodItem(name: 'Quinoa', emoji: '🌿', calories: 120, protein: 4.4, carbs: 21, fat: 1.9, serving: '100g', category: 'Carbs'),
    FoodItem(name: 'Orange', emoji: '🍊', calories: 47, protein: 0.9, carbs: 12, fat: 0.1, serving: '1 medium', category: 'Fruits'),
    FoodItem(name: 'Tofu', emoji: '⬜', calories: 76, protein: 8, carbs: 1.9, fat: 4.8, serving: '100g', category: 'Protein'),
    FoodItem(name: 'Cashews', emoji: '🥜', calories: 157, protein: 5.2, carbs: 9, fat: 12, serving: '30g', category: 'Snacks'),
  ];

  static const List<Exercise> exercises = [
    Exercise(name: 'Bench Press', emoji: '🏋️', category: 'Strength', caloriesBurned: 220, duration: '45 min', muscleGroups: ['Chest', 'Triceps', 'Shoulders'], difficulty: 'Intermediate', steps: ['Set bench to flat position and load barbell.', 'Lie back, grip bar slightly wider than shoulder-width.', 'Unrack bar and lower slowly to mid-chest over 3 seconds.', 'Press back up explosively, feet flat on floor.', 'Perform 3–4 sets of 8–12 reps with 90-sec rest.']),
    Exercise(name: 'Pull-ups', emoji: '💪', category: 'Strength', caloriesBurned: 150, duration: '20 min', muscleGroups: ['Back', 'Biceps', 'Core'], difficulty: 'Intermediate', steps: ['Hang from bar, overhand grip shoulder-width apart.', 'Engage core, retract shoulder blades before pulling.', 'Pull until chin clears the bar, leading with elbows.', 'Lower slowly with control — 3 seconds down.', '3 sets of max reps with 2-min rest.']),
    Exercise(name: 'Running', emoji: '🏃', category: 'Cardio', caloriesBurned: 450, duration: '45 min', muscleGroups: ['Legs', 'Core', 'Cardiovascular'], difficulty: 'Beginner', steps: ['Warm up with 5-min brisk walk.', 'Maintain upright posture, slight forward lean.', 'Land midfoot beneath your center of mass.', 'Breathe rhythmically — inhale 3, exhale 2 counts.', 'Cool down 5-min easy jog then stretch.']),
    Exercise(name: 'HIIT Tabata', emoji: '⚡', category: 'HIIT', caloriesBurned: 380, duration: '20 min', muscleGroups: ['Full Body', 'Cardiovascular'], difficulty: 'Advanced', steps: ['Choose 8 exercises (burpees, jump squats, etc).', 'Work at max intensity for 20 seconds each.', 'Rest exactly 10 seconds between exercises.', 'Complete 8 rounds (4 minutes) per group.', 'Cool down with deep breathing and stretching.']),
    Exercise(name: 'Deadlift', emoji: '🔱', category: 'Strength', caloriesBurned: 300, duration: '40 min', muscleGroups: ['Lower Back', 'Glutes', 'Hamstrings'], difficulty: 'Advanced', steps: ['Stand feet hip-width, bar over mid-foot.', 'Hinge at hips, grip bar just outside knees.', 'Brace core, chest up, squeeze lats.', 'Drive through heels extending hips and knees.', 'Lower with control, reset between reps.']),
    Exercise(name: 'Yoga Flow', emoji: '🧘', category: 'Yoga', caloriesBurned: 180, duration: '60 min', muscleGroups: ['Full Body', 'Flexibility'], difficulty: 'Beginner', steps: ['Begin in Mountain Pose, 5 deep breaths.', 'Sun Salutation A x3 rounds to warm up.', 'Warrior I, II, III for 5 breaths each side.', 'Seated poses: forward fold, pigeon, twist.', 'End with 5-min Savasana.']),
    Exercise(name: 'Jump Rope', emoji: '🪢', category: 'Cardio', caloriesBurned: 400, duration: '30 min', muscleGroups: ['Legs', 'Shoulders', 'Core'], difficulty: 'Beginner', steps: ['Adjust rope to armpit height.', 'Start with basic two-foot jumps 60 RPM.', 'Use wrists to turn rope, not full arms.', 'Alternate 30s fast, 30s slow for 10 rounds.', 'Progress to alternating feet and double-unders.']),
    Exercise(name: 'Plank', emoji: '⏱', category: 'HIIT', caloriesBurned: 120, duration: '15 min', muscleGroups: ['Core', 'Shoulders', 'Glutes'], difficulty: 'Beginner', steps: ['Place forearms on floor, elbows under shoulders.', 'Lift hips, straight line head to heels.', 'Squeeze glutes, core, and quads throughout.', 'Breathe normally, hold 30–60 seconds.', 'Repeat 3–5 times with 30s rest.']),
    Exercise(name: 'Squats', emoji: '🦵', category: 'Strength', caloriesBurned: 250, duration: '35 min', muscleGroups: ['Quads', 'Glutes', 'Hamstrings'], difficulty: 'Beginner', steps: ['Stand feet shoulder-width, toes slightly out.', 'Brace core, chest up throughout.', 'Push knees out as you descend.', 'Lower until thighs parallel or below.', '3–4 sets of 10–15 reps.']),
    Exercise(name: 'Push-ups', emoji: '🤸', category: 'Strength', caloriesBurned: 170, duration: '20 min', muscleGroups: ['Chest', 'Triceps', 'Core'], difficulty: 'Beginner', steps: ['High plank, hands slightly wider than shoulders.', 'Straight line head to heels throughout.', 'Lower chest to floor, elbows at 45 degrees.', 'Push back up explosively.', '3–5 sets of 10–20 reps.']),
    Exercise(name: 'Cycling', emoji: '🚴', category: 'Cardio', caloriesBurned: 350, duration: '45 min', muscleGroups: ['Legs', 'Glutes', 'Cardiovascular'], difficulty: 'Beginner', steps: ['Adjust seat — slight knee bend at pedal bottom.', 'Warm up at low resistance for 5 minutes.', 'Maintain 70–90 RPM cadence.', 'Keep back straight, core engaged.', 'Cool down 5 min at low resistance.']),
    Exercise(name: 'Swimming', emoji: '🏊', category: 'Cardio', caloriesBurned: 500, duration: '45 min', muscleGroups: ['Full Body', 'Cardiovascular'], difficulty: 'Intermediate', steps: ['Warm up 5-min easy backstroke.', 'Exhale underwater, inhale to the side.', 'Freestyle stroke for max cardio benefit.', 'Kick from hips, not knees.', 'Intervals: 2 lengths fast, 1 slow.']),
  ];

  static const List<Recipe> recipes = [
    Recipe(name: 'Egg Fried Rice', emoji: '🍳', ingredients: ['Eggs', 'Rice', 'Onion', 'Garlic', 'Olive Oil'], calories: 420, protein: 18, cookTime: '15 min', difficulty: 'Easy', description: 'Quick protein-rich fried rice with scrambled eggs.', steps: ['Cook rice and let it cool.', 'Heat oil, add garlic and onion, stir-fry 2 min.', 'Push vegetables aside, scramble eggs in center.', 'Add cold rice, mix vigorously.', 'Season with soy sauce, salt, pepper.']),
    Recipe(name: 'Chicken Stir Fry', emoji: '🥘', ingredients: ['Grilled Chicken', 'Broccoli', 'Onion', 'Olive Oil', 'Garlic'], calories: 380, protein: 35, cookTime: '25 min', difficulty: 'Medium', description: 'Lean chicken with fresh broccoli in light garlic sauce.', steps: ['Cut chicken, season with salt and pepper.', 'Cook chicken 6-7 min until golden. Set aside.', 'Stir-fry onion and garlic 2 min.', 'Add broccoli, 2 tbsp water, cover 3 min.', 'Return chicken, add soy sauce, toss.']),
    Recipe(name: 'Paneer Bhurji', emoji: '🧀', ingredients: ['Paneer', 'Tomato', 'Onion', 'Garlic', 'Chilli'], calories: 310, protein: 22, cookTime: '20 min', difficulty: 'Easy', description: 'Scrambled cottage cheese with spiced vegetables.', steps: ['Crumble paneer coarsely.', 'Heat oil, add cumin seeds until they splutter.', 'Cook onion golden brown, add garlic, ginger, chilli.', 'Add tomatoes, cook until oil separates.', 'Add spices, then paneer, mix gently 3 min.']),
    Recipe(name: 'Masoor Dal', emoji: '🍲', ingredients: ['Lentils', 'Tomato', 'Onion', 'Chilli', 'Garlic'], calories: 280, protein: 18, cookTime: '30 min', difficulty: 'Easy', description: 'Hearty red lentil dal packed with protein and iron.', steps: ['Rinse lentils, boil with water, turmeric, salt 20 min.', 'Heat oil, add mustard seeds.', 'Cook onion caramelized 8-10 min.', 'Add garlic, tomatoes, spices. Cook 5 min.', 'Combine with dal, simmer 5 min.']),
    Recipe(name: 'Banana Oat Smoothie', emoji: '🥤', ingredients: ['Banana', 'Oats', 'Whole Milk'], calories: 350, protein: 12, cookTime: '5 min', difficulty: 'Easy', description: 'Creamy filling smoothie — perfect pre/post workout.', steps: ['Add 40g oats to blender.', 'Add banana chunks (frozen is great).', 'Pour 200ml cold milk.', 'Add 1 tsp honey, pinch of cinnamon.', 'Blend 45-60 seconds until smooth.']),
    Recipe(name: 'Avocado Egg Toast', emoji: '🥑', ingredients: ['Whole Egg', 'Avocado', 'Whole Wheat Bread'], calories: 320, protein: 14, cookTime: '10 min', difficulty: 'Easy', description: 'Healthy fats and protein on whole wheat bread.', steps: ['Toast bread until golden.', 'Mash avocado with salt, pepper, lemon.', 'Fry or poach egg to preference.', 'Spread avocado on toast.', 'Top with egg, add chilli flakes.']),
    Recipe(name: 'High Protein Bowl', emoji: '🥗', ingredients: ['Grilled Chicken', 'Broccoli', 'White Rice', 'Olive Oil'], calories: 490, protein: 42, cookTime: '30 min', difficulty: 'Medium', description: 'The ultimate gym meal bowl — macro balanced.', steps: ['Cook rice.', 'Season and grill chicken 6-7 min each side.', 'Steam broccoli 4-5 min.', 'Slice chicken into strips.', 'Assemble bowl, drizzle olive oil.']),
    Recipe(name: 'Greek Yogurt Parfait', emoji: '🧁', ingredients: ['Greek Yogurt', 'Banana', 'Almonds', 'Oats'], calories: 380, protein: 28, cookTime: '5 min', difficulty: 'Easy', description: 'No-cook high-protein breakfast or snack.', steps: ['Layer 150g Greek yogurt in glass.', 'Add 20g rolled oats.', 'Slice half banana on top.', 'Sprinkle 15g almonds.', 'Drizzle honey, eat immediately.']),
  ];

  static const List<String> ingredients = [
    'Eggs', 'Chicken', 'Rice', 'Broccoli', 'Milk', 'Banana',
    'Onion', 'Tomato', 'Lentils', 'Garlic', 'Olive Oil', 'Paneer',
    'Oats', 'Avocado', 'Chilli', 'Bread', 'Yogurt', 'Peanut Butter',
    'Sweet Potato', 'Salmon',
  ];

  static const List<String> exerciseCategories = ['All', 'Strength', 'Cardio', 'HIIT', 'Yoga'];
}
