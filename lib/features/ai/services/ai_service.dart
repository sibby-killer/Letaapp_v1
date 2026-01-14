import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';

class AIService {
  // Analyze user query using Groq AI
  Future<Map<String, dynamic>> analyzeQuery(String query) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a smart assistant for a delivery app. '
                  'Extract product categories and keywords from user queries. '
                  'Respond ONLY with JSON format: {"categories": ["food", "gas"], "keywords": ["pizza", "refill"]}'
            },
            {
              'role': 'user',
              'content': query,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI request failed');
      }

      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      
      // Parse AI response
      final aiResponse = json.decode(content);
      
      return {
        'categories': aiResponse['categories'] ?? [],
        'keywords': aiResponse['keywords'] ?? [],
      };
    } catch (e) {
      // Fallback: simple keyword extraction
      return {
        'categories': _extractSimpleCategories(query),
        'keywords': _extractSimpleKeywords(query),
      };
    }
  }

  // Simple fallback category extraction
  List<String> _extractSimpleCategories(String query) {
    final lowerQuery = query.toLowerCase();
    final categories = <String>[];

    if (lowerQuery.contains('food') || 
        lowerQuery.contains('pizza') || 
        lowerQuery.contains('burger') ||
        lowerQuery.contains('chapo')) {
      categories.add('food');
    }

    if (lowerQuery.contains('gas') || 
        lowerQuery.contains('refill') || 
        lowerQuery.contains('cylinder')) {
      categories.add('gas');
    }

    if (lowerQuery.contains('second-hand') || 
        lowerQuery.contains('used') || 
        lowerQuery.contains('vintage')) {
      categories.add('second-hand');
    }

    return categories;
  }

  // Simple fallback keyword extraction
  List<String> _extractSimpleKeywords(String query) {
    return query
        .toLowerCase()
        .split(' ')
        .where((word) => word.length > 3)
        .toList();
  }

  // Get smart suggestions
  Future<List<String>> getSmartSuggestions(String partialQuery) async {
    // Common suggestions based on partial input
    final commonQueries = [
      'I need gas refill',
      'Order pizza near me',
      'Find second-hand electronics',
      'Get groceries delivered',
      'I want chapo and beans',
      'Buy vintage clothes',
    ];

    return commonQueries
        .where((q) => q.toLowerCase().contains(partialQuery.toLowerCase()))
        .take(5)
        .toList();
  }
}
