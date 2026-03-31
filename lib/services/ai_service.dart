import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

class AIService {
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  late final GenerativeModel _model;
  late final ChatSession _chat;

  AIService() {
    if (_apiKey.isEmpty) {
      debugPrint('Warning: GEMINI_API_KEY is not set. AI features will be unavailable.');
    }
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
  }

  // 1. Generate Smart Replies
  Future<List<String>> generateSmartReplies(String lastMessageContent) async {
    final prompt = "You are a helpful chat assistant. Given this last message: '$lastMessageContent', suggest exactly 3 very short (1-3 words) natural conversational replies. Return only a JSON array of strings.";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "[]";
      // Basic JSON cleanup if needed
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return List<String>.from(jsonDecode(cleanJson));
    } catch (e) {
      debugPrint("AI Error: $e");
      return ["Great!", "Okay", "Sounds good"];
    }
  }

  // 2. Chat with Assistant
  Future<String> chatWithAssistant(String userMessage) async {
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      debugPrint("AI Chat Error: $e");
      return "Something went wrong. Please check your connection.";
    }
  }

  // 3. Translate Message
  Future<String> translateText(String text, String targetLanguage) async {
    final prompt = "Translate this text to $targetLanguage. Only return the translated text: '$text'";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? text;
    } catch (e) {
      debugPrint("AI Translation Error: $e");
      return text;
    }
  }
}
