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

  // Generate store description from store name using AI
  Future<String> generateStoreDescription(String storeName, {String? category}) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final prompt = category != null
          ? 'Generate a short, professional store description (2-3 sentences) for a $category store called "$storeName" in Kakamega, Kenya. Make it welcoming and highlight quality service.'
          : 'Generate a short, professional store description (2-3 sentences) for a store called "$storeName" in Kakamega, Kenya. Make it welcoming and highlight quality service.';

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
              'content': 'You are a helpful assistant that writes compelling store descriptions for small businesses in Kenya. Keep descriptions short, friendly, and professional. Do not use quotes in your response.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI request failed');
      }

      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      
      return content.trim();
    } catch (e) {
      // Fallback description
      return _generateFallbackDescription(storeName, category);
    }
  }

  // Fallback description generator
  String _generateFallbackDescription(String storeName, String? category) {
    final templates = [
      'Welcome to $storeName! We are dedicated to providing quality products and excellent service to our customers in Kakamega.',
      '$storeName is your trusted local shop for all your needs. We pride ourselves on fast delivery and customer satisfaction.',
      'At $storeName, we believe in quality and convenience. Visit us for the best products and friendly service in town.',
    ];
    
    return templates[storeName.length % templates.length];
  }

  // Generate multiple description options for user to choose
  Future<List<String>> generateDescriptionOptions(String storeName, {String? category}) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final prompt = category != null
          ? 'Generate 3 different short store descriptions (2-3 sentences each) for a $category store called "$storeName" in Kakamega, Kenya. Number them 1, 2, 3. Each should have a different tone: professional, friendly, and catchy.'
          : 'Generate 3 different short store descriptions (2-3 sentences each) for a store called "$storeName" in Kakamega, Kenya. Number them 1, 2, 3. Each should have a different tone: professional, friendly, and catchy.';

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
              'content': 'You are a helpful assistant that writes compelling store descriptions for small businesses in Kenya. Format your response as three numbered options.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI request failed');
      }

      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      
      // Parse the numbered options
      final options = <String>[];
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      String currentOption = '';
      for (final line in lines) {
        if (RegExp(r'^[1-3][\.\)]').hasMatch(line.trim())) {
          if (currentOption.isNotEmpty) {
            options.add(currentOption.trim());
          }
          currentOption = line.replaceFirst(RegExp(r'^[1-3][\.\)]\s*'), '');
        } else {
          currentOption += ' $line';
        }
      }
      if (currentOption.isNotEmpty) {
        options.add(currentOption.trim());
      }
      
      return options.take(3).toList();
    } catch (e) {
      // Return fallback options
      return [
        'Welcome to $storeName! We offer quality products and fast delivery to customers in Kakamega.',
        '$storeName - Your trusted local shop for all your needs. Great prices and friendly service!',
        'Discover $storeName, where quality meets convenience. Serving the MMUST community with pride.',
      ];
    }
  }
}
