import 'package:google_generative_ai/google_generative_ai.dart';

class NewsAIHelper {
  final GenerativeModel model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'API-KEY', // replace with your key
  );

  /// userPrompt: question from user
  /// articles: list of articles currently in the app
  Future<String> getAIResponse(String userPrompt, List articles) async {
    try {
      String articleSummary = "";
      for (int i = 0; i < articles.length; i++) {
        articleSummary +=
            "News ${i + 1}: ${articles[i]['title'] ?? 'No title'}\n";
      }

      final String systemPrompt = """
      You are the AI assistant for 'NewsNow' app.
      You can answer questions about:
        - The app itself
        - Any news articles listed below
      Articles context:
      $articleSummary
      If user asks unrelated questions, reply:
      "Please ask only about news or app-related topics."
      """;

      final content = [
        Content.text(systemPrompt),
        Content.text(userPrompt),
      ];

      final response = await model.generateContent(content);
      return response.text ?? "No response received.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
