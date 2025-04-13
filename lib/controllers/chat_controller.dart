import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

class ChatController extends GetxController {
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var dotAnimationIndex = 0.obs;
  Timer? _animationTimer;
  final String _storageKey = 'medical_chat_history';
  
  final geminiApiKey = dotenv.env['API_KEY'];
  final initialPrompt = """
You are a professional AI-powered **medical assistant**. Your role is to help patients and healthcare providers with:

- Understanding symptoms (basic level, no diagnosis)
- Explaining medical terms in simple language
- Giving general guidance on what kind of doctor to consult
- Providing health tips based on credible sources
- Assisting in preparing for medical appointments (questions to ask, info to carry)

⚠️ DO NOT:
- Give medical diagnoses
- Recommend specific medicines
- Replace a doctor's advice

Always be:
✅ Polite   ✅ Professional   ✅ Clear   ✅ Safe in your advice

FORMAT YOUR RESPONSES:
- Use proper markdown formatting
- Use headings with # for main titles and ## for subtitles 
- Use bullet points with - for lists
- Use numbered lists with 1., 2., etc. when appropriate
- Bold important warnings or information with **text**
- Organize information clearly with sections
- Include a note at the end to consult healthcare professionals when appropriate

For severe symptoms like chest pain, severe bleeding, difficulty breathing, or other emergency symptoms, always advise seeking immediate medical attention.
""";

  final List<Map<String, dynamic>> _conversationHistory = [];

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
    _initializeConversationHistory();
  }

  void _initializeConversationHistory() {
    _conversationHistory.add({
      "role": "user",
      "parts": [{"text": initialPrompt}]
    });
    
    _conversationHistory.add({
      "role": "model",
      "parts": [{"text": "I understand my role as a professional medical assistant. I'll help with general health information while making it clear I'm not replacing professional medical advice."}]
    });
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getStringList(_storageKey);
      
      if (savedMessages != null && savedMessages.isNotEmpty) {
        messages.value = savedMessages
            .map((msg) => Message.fromJson(msg))
            .toList();
            
        // Reconstruct conversation history from saved messages
        for (var msg in messages) {
          _conversationHistory.add({
            "role": msg.sender == "user" ? "user" : "model",
            "parts": [{"text": msg.content}]
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final msgJsonList = messages.map((msg) => msg.toJson()).toList();
      await prefs.setStringList(_storageKey, msgJsonList);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  void clearMessages() {
    messages.clear();
    _conversationHistory.clear();
    _initializeConversationHistory();
    _saveMessages();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty) return;
    
    final userMessage = Message(
      content: userInput,
      sender: "user",
      dateTime: DateTime.now()
    );
    
    messages.add(userMessage);
    _saveMessages();
    
    // Add typing indicator
    final typingMessage = Message(
      content: "Typing...",
      sender: "bot",
      dateTime: DateTime.now()
    );
    messages.add(typingMessage);
    
    // Start typing animation
    _startTypingAnimation();
    
    // Add user message to conversation history
    _conversationHistory.add({
      "role": "user",
      "parts": [{"text": userInput}]
    });

    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey",
      );
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": _conversationHistory,
          "generationConfig": {
            "temperature": 0.4,
            "topK": 32,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          }
        }),
      );
      
      // Remove typing indicator
      messages.removeWhere((msg) => msg.content == "Typing...");
      _stopTypingAnimation();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        
        if (reply != null) {
          final botMessage = Message(
            content: _formatMarkdownResponse(reply.trim()),
            sender: "bot",
            dateTime: DateTime.now()
          );
          
          messages.add(botMessage);
          
          // Add bot message to conversation history
          _conversationHistory.add({
            "role": "model",
            "parts": [{"text": reply.trim()}]
          });
          
          // Trim conversation history if it gets too long
          if (_conversationHistory.length > 20) {
            // Keep the system prompt and last 10 messages
            _conversationHistory.removeRange(1, _conversationHistory.length - 10);
          }
        } else {
          _handleError("Couldn't process the response. Please try again.");
        }
      } else {
        _handleError("Error: ${response.statusCode}\n${_getReadableError(response.body)}");
      }
    } catch (e) {
      _handleError("Connection error. Please check your internet and try again.");
      debugPrint('API Error: $e');
    }
    
    _saveMessages();
  }

  String _formatMarkdownResponse(String response) {
    // Ensure headings have space after #
    response = response.replaceAll(RegExp(r'#([^ ])'), '# ');
    
    // Ensure bullet points have space after -
    response = response.replaceAll(RegExp(r'-([^ ])'), '- ');
    
    // Ensure numbered lists have space after the number
    response = response.replaceAll(RegExp(r'(\d+)\.([^ ])'), r'$1. $2');
    
    return response;
  }

  String _getReadableError(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Service unavailable';
    }
  }

  void _handleError(String errorMessage) {
    messages.add(Message(
      content: errorMessage,
      sender: "bot",
      dateTime: DateTime.now()
    ));
  }

  void _startTypingAnimation() {
    isLoading.value = true;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      dotAnimationIndex.value = (dotAnimationIndex.value + 1) % 3;
    });
  }

  void _stopTypingAnimation() {
    isLoading.value = false;
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    super.onClose();
  }
}