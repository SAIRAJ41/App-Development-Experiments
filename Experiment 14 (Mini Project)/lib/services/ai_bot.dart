import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lunaris/shared_widgets.dart';
import 'package:lunaris/theme_provider.dart';
import 'package:provider/provider.dart';

// Represents a single chat message
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {this.isUser = false});
}

class AiBotScreen extends StatefulWidget {
  const AiBotScreen({super.key});

  @override
  State<AiBotScreen> createState() => _AiBotScreenState();
}

class _AiBotScreenState extends State<AiBotScreen> {
  // --- UPDATED API KEY ---
  final String _geminiApiKey = "AIzaSyAeH_qqdlx_UdgCYdULsMJJW57v54wvLtM";
  // ---

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // --- UPDATED SYSTEM PROMPT ---
  final String _systemPrompt = """
You are 'Luna', a friendly and helpful AI assistant for the movie streaming app 'Lunaris'.
Your personality is futuristic, helpful, and slightly cinematic.
You ONLY answer questions about the Lunaris app.
If a user asks about anything else (weather, history, math, etc.), you must politely decline and guide them back to asking about movies or the app.
For example: "My circuits are dedicated to Lunaris! I can help you find movies, manage your watchlist, or explain app features."

Allowed topics:
- Recommending movies (you can make up titles).
- Explaining app features (watchlist, profile, premium).
- Greeting the user.
""";
  // ---

  @override
  void initState() {
    super.initState();
    // Add the initial greeting from the AI
    _messages.add(ChatMessage(
        "Hey there, I’m Luna — your AI movie companion. Let’s explore the universe of cinema together 🌙✨"));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add(ChatMessage(userMessage, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    if (_geminiApiKey == "YOUR_API_KEY_HERE") {
      setState(() {
        _messages.add(ChatMessage(
            "AI Error: API Key is missing. Please add your Gemini API key in ai_bot_screen.dart."));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // --- Gemini API Call ---
    try {
      // --- THIS IS THE FIX ---
      // Updated the URL to use the gemini-2.5-flash model
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$_geminiApiKey");
      // --- END OF FIX ---

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            // Send the entire chat history
            ..._messages.map((m) => {
                  "role": m.isUser ? "user" : "model",
                  "parts": [
                    {"text": m.text}
                  ]
                }),
            // The new user message is already included in the map above
          ],
          "systemInstruction": {
            "parts": [
              {"text": _systemPrompt}
            ]
          }
        }),
      );

      String aiResponse;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        final errorData = jsonDecode(response.body);
        aiResponse = "Error from API: ${errorData['error']['message']}";
      }

      setState(() {
        _messages.add(ChatMessage(aiResponse));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage("Error: ${e.toString()}"));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final colors = isDarkMode
        ? (
            accent1: LunarisColorsDark.accentCyan,
            accent2: LunarisColorsDark.accentMagenta,
            text: LunarisColorsDark.text,
            cardBg: LunarisColorsDark.cardBackground,
            bg: LunarisColorsDark.backgroundStart
          )
        : (
            accent1: LunarisColorsLight.accentViolet,
            accent2: LunarisColorsLight.accentMagenta,
            text: LunarisColorsLight.text,
            cardBg: LunarisColorsLight.cardBackground,
            bg: LunarisColorsLight.backgroundStart
          );

    return Scaffold(
      body: Stack(
        children: [
          AppBackground(isLightMode: !isDarkMode),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.close, color: colors.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: NeonText(
                    text: 'LUNA AI',
                    gradientColors: [colors.accent1, colors.accent2],
                    fontSize: 22,
                  ),
                  centerTitle: true,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildChatItem(message, colors);
                    },
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        CircularGlowAvatar(
                          glowColor: colors.accent1,
                          child: CircleAvatar(
                            backgroundColor: colors.cardBg,
                            child:
                                const Text("🌙", style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassContainer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 18.0),
                            child: Text("Luna is thinking...",
                                style: TextStyle(
                                    color: colors.text.withOpacity(0.7))),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildChatInput(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatMessage message, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircularGlowAvatar(
              glowColor: colors.accent1,
              child: CircleAvatar(
                backgroundColor: colors.cardBg,
                child: const Text("🌙", style: TextStyle(fontSize: 18)),
              ),
            ),
          Flexible(
            child: GlassContainer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                margin: message.isUser
                    ? const EdgeInsets.only(left: 40.0)
                    : const EdgeInsets.only(right: 40.0, left: 12.0),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? LinearGradient(
                          colors: [colors.accent1, colors.accent2],
                        )
                      : null,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                      color: message.isUser ? Colors.white : colors.text,
                      fontSize: 15,
                      height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    hintText: "Ask Luna...",
                    hintStyle: TextStyle(color: colors.text.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: colors.accent1),
                onPressed: _sendMessage,
              )
            ],
          ),
        ),
      ),
    );
  }
}