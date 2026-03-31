import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  // Replace with your Anthropic API key from https://console.anthropic.com
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';

  static Future<String> chat({required String userMessage, required List<Map<String, String>> history, required String systemContext}) async {
    try {
      final messages = [...history.map((m) => {'role': m['role']!, 'content': m['content']!}), {'role': 'user', 'content': userMessage}];
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey, 'anthropic-version': '2023-06-01'},
        body: jsonEncode({'model': 'claude-sonnet-4-20250514', 'max_tokens': 500, 'system': systemContext, 'messages': messages}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
      return _fallback(userMessage);
    } catch (e) {
      return _fallback(userMessage);
    }
  }

  static String _fallback(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('protein')) return "Great question about protein! 💪 Aim for 1.6–2.2g per kg of bodyweight. Good sources: chicken, eggs, paneer, Greek yogurt, lentils.";
    if (lower.contains('calori')) return "Calories are the foundation of nutrition! 🔥 For weight loss, aim for a 300–500 kcal deficit. Track consistently and adjust every 2 weeks.";
    if (lower.contains('dinner') || lower.contains('eat')) return "For dinner, try grilled chicken with sweet potato and broccoli 🍗 — about 450 kcal with 40g protein. Perfect macro balance!";
    if (lower.contains('workout') || lower.contains('exercise')) return "Pair your workout with proper nutrition ⚡ — eat carbs + protein 1-2 hours before, and refuel within 30 minutes after!";
    if (lower.contains('water')) return "Aim for 2.5–3L daily! 💧 Drink a glass first thing in the morning and before each meal for best results.";
    if (lower.contains('snack')) return "Healthy snacks under 200 kcal 🥗: Greek yogurt with berries, almonds, apple with peanut butter, or a boiled egg with veggies!";
    return "I'm NutriBot, your AI nutrition coach! 🤖 Ask me about meals, macros, workouts, recipes, or anything health-related!";
  }
}
