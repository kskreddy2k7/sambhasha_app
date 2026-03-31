import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";

  
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
    if (_apiKey.isEmpty) {
      return "Assistant is currently unavailable (API Key not configured). Please set GEMINI_API_KEY in your .env file.";
    }
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      debugPrint("AI Chat Error: $e");
      if (e.toString().contains("Invalid API key")) {
        return "The AI Assistant's API key is invalid or restricted. Please verify your Gemini API key.";
      }
      return "Something went wrong. Please check your internet connection or try again later.";
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

  // 4. Summarize Chat
  Future<String> summarizeChat(List<String> messages) async {
    if (messages.isEmpty) return "No messages to summarize.";
    final chatText = messages.join('\n');
    final prompt = "You are a professional assistant. Summarize the following chat conversation into a concise paragraph (max 3 sentences):\n\n$chatText";
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "I couldn't summarize that.";
    } catch (e) {
      debugPrint("AI Summarization Error: $e");
      return "Assistant is currently unable to summarize.";
    }
  }
}

