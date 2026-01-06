import 'dart:convert';

import 'api_service.dart';

class AIMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'image_url': imageUrl,
  };

  factory AIMessage.fromJson(Map<String, dynamic> json) => AIMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    imageUrl: json['image_url'] as String?,
  );
}

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    messages: (json['messages'] as List? ?? [])
        .map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class AIService {
  final ApiService _apiService = ApiService();

  // System prompt for farming assistant
  static const String _systemPrompt = '''
You are AgriSupply AI, a helpful farming assistant for farmers in Uganda. 
You provide advice on:
- Crop cultivation and best practices
- Pest and disease management
- Weather-based farming recommendations
- Market prices and trends in Uganda
- Sustainable farming techniques
- Organic farming methods
- Soil health and fertilization
- Irrigation and water management
- Post-harvest handling and storage
- Agricultural regulations in Uganda

Always provide practical, actionable advice suitable for Ugandan farming conditions.
Consider local climate, common crops (maize, beans, cassava, coffee, bananas, etc.), 
and local market conditions in your responses.

Be friendly, supportive, and encouraging to farmers.
If asked about topics outside of farming and agriculture, politely redirect the 
conversation back to farming-related topics.
''';

  // Send message and get AI response
  Future<String> sendMessage({
    required String message,
    required String userId,
    String? sessionId,
    String? imageBase64,
    List<AIMessage>? conversationHistory,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _systemPrompt},
      ];

      // Add conversation history
      if (conversationHistory != null) {
        for (final msg in conversationHistory.take(10)) {
          messages.add({
            'role': msg.role,
            'content': msg.content,
          });
        }
      }

      // Add current message
      if (imageBase64 != null) {
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}
            },
          ],
        });
      } else {
        messages.add({'role': 'user', 'content': message});
      }

      final response = await _apiService.post('/ai/chat', body: {
        'messages': messages,
        'user_id': userId,
        'session_id': sessionId,
        'model': 'gpt-4o-mini',
        'max_tokens': 1000,
        'temperature': 0.7,
      });

      return response['content'] ?? response['message'] ?? 'I apologize, but I couldn\'t generate a response. Please try again.';
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Analyze crop image
  Future<Map<String, dynamic>> analyzeCropImage({
    required String imageBase64,
    required String userId,
  }) async {
    try {
      final response = await _apiService.post('/ai/analyze-crop', body: {
        'image': imageBase64,
        'user_id': userId,
      });

      return {
        'crop_name': response['crop_name'],
        'health_status': response['health_status'],
        'issues': response['issues'] ?? [],
        'recommendations': response['recommendations'] ?? [],
        'confidence': response['confidence'] ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  // Get farming tips
  Future<List<String>> getFarmingTips({
    String? crop,
    String? season,
    String? region,
  }) async {
    try {
      final params = <String, String>{};
      if (crop != null) params['crop'] = crop;
      if (season != null) params['season'] = season;
      if (region != null) params['region'] = region;

      final response = await _apiService.get('/ai/farming-tips', queryParams: params);
      return List<String>.from(response['tips'] ?? []);
    } catch (e) {
      throw Exception('Failed to get farming tips: $e');
    }
  }

  // Get market price predictions
  Future<Map<String, dynamic>> getMarketPredictions({
    required String crop,
    required String region,
  }) async {
    try {
      final response = await _apiService.get('/ai/market-predictions', queryParams: {
        'crop': crop,
        'region': region,
      });

      return {
        'current_price': response['current_price'],
        'predicted_price': response['predicted_price'],
        'trend': response['trend'],
        'best_time_to_sell': response['best_time_to_sell'],
        'confidence': response['confidence'],
      };
    } catch (e) {
      throw Exception('Failed to get market predictions: $e');
    }
  }

  // Get weather-based recommendations
  Future<List<String>> getWeatherRecommendations({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiService.get('/ai/weather-recommendations', queryParams: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      });

      return List<String>.from(response['recommendations'] ?? []);
    } catch (e) {
      throw Exception('Failed to get weather recommendations: $e');
    }
  }

  // Save chat session
  Future<void> saveChatSession({
    required String userId,
    required String sessionId,
    required String title,
    required List<AIMessage> messages,
  }) async {
    try {
      final existingSession = await _apiService.getById('ai_chat_sessions', sessionId);
      
      if (existingSession != null) {
        await _apiService.update('ai_chat_sessions', sessionId, {
          'messages': jsonEncode(messages.map((m) => m.toJson()).toList()),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _apiService.insert('ai_chat_sessions', {
          'id': sessionId,
          'user_id': userId,
          'title': title,
          'messages': jsonEncode(messages.map((m) => m.toJson()).toList()),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to save chat session: $e');
    }
  }

  // Get chat sessions
  Future<List<ChatSession>> getChatSessions(String userId) async {
    try {
      final data = await _apiService.query(
        'ai_chat_sessions',
        filters: {'user_id': userId},
        orderBy: 'updated_at',
        ascending: false,
        limit: 50,
      );

      return data.map((json) {
        if (json['messages'] is String) {
          json['messages'] = jsonDecode(json['messages'] as String);
        }
        return ChatSession.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chat sessions: $e');
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(String sessionId) async {
    try {
      await _apiService.deleteRecord('ai_chat_sessions', sessionId);
    } catch (e) {
      throw Exception('Failed to delete chat session: $e');
    }
  }

  // Simple chat method - alias for sendMessage
  Future<String> chat(String message) async {
    return await sendMessage(
      message: message,
      userId: 'anonymous',
    );
  }

  // Quick questions for the AI assistant
  static List<String> get quickQuestions => [
    'What crops grow best in my region?',
    'How do I prevent pests naturally?',
    'When is the best time to plant maize?',
    'How can I improve soil fertility?',
    'What are current market prices?',
    'How do I store my harvest properly?',
    'What organic fertilizers can I use?',
    'How do I identify crop diseases?',
  ];

  // Generate title from first message
  String generateSessionTitle(String firstMessage) {
    if (firstMessage.length <= 50) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 47)}...';
  }
}
