// lib/pages/ai_assistant_page.dart

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIAssistantPage extends StatefulWidget {
  final List articles; // receive articles from HomePage

  const AIAssistantPage({Key? key, required this.articles}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  late ChatSession _chat;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // ====== IMPORTANT =======
    // DO NOT hardcode API keys in production. Use secure storage / server side or environment variables.
    const apiKey = 'API-Key';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // or another model you have access to
      apiKey: apiKey,
    );

    // Build article context text
    String articleContext = "";
    for (int i = 0; i < widget.articles.length; i++) {
      final title = widget.articles[i]['title'] ?? "No title";
      final desc = widget.articles[i]['description'] ?? "";
      articleContext += "News ${i + 1}: $title. $desc\n";
    }

    final systemInstructionString =
        """
You are an AI assistant for the 'NewsNow' app.
You are here to help the user understand the news they are currently viewing.
You can answer questions about:
 - The 'NewsNow' app itself (features, usage).
 - Any of the news articles provided below.
Articles context:
$articleContext

If the user asks unrelated questions, reply:
"Please ask only about the news articles or app-related topics."
""";

    // Pass the system instruction as chat history so model treats it as system context.
    // (startChat accepts history: List<Content> and generationConfig: GenerationConfig)
    _chat = model.startChat(history: [Content.text(systemInstructionString)]);

    // initial greeting message
    _messages.add({
      "role": "bot",
      "text":
          "Hello! I'm your NewsNow assistant. Ask me anything about the articles or the app.",
    });
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": userInput});
      _controller.clear();
      _loading = true;
    });

    // scroll to bottom after inserting user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // send message via chat session (history handled automatically by ChatSession)
      final response = await _chat.sendMessage(Content.text(userInput));

      final reply = response.text ?? "No response from model.";
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "text": reply});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text":
                "Error: failed to get response. Check API key, billing, permissions, and network. Details: $e",
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        // scroll again after receiving response
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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _chatBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser
                ? const Radius.circular(12)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(12),
          ),
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧠 NewsNow AI Assistant"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _chatBubble(_messages[index]),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_loading,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Ask about news or the app...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: CircularProgressIndicator(),
                      )
                    : FloatingActionButton(
                        mini: true,
                        onPressed: _sendMessage,
                        backgroundColor: Colors.blueAccent,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
