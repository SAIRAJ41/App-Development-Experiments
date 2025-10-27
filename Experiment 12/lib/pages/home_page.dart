// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../consts.dart';
import 'profile_page.dart';
import 'ai_assistant_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> articles = [];
  bool isLoading = false;
  int _currentIndex = 0; // 👈 to track current tab

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() => isLoading = true);

    try {
      final response = await Dio().get(baseUrl);
      if (mounted) {
        setState(() {
          articles = response.data["articles"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching news: $e");
      if (mounted) setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load news. Check your internet or API key."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- Pages for each navigation tab ---
  Widget _buildNewsPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchNews,
        child: const Center(
          child: Text("No news available.", style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchNews,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final news = articles[index];
          final imageUrl =
              news["urlToImage"] ?? "https://via.placeholder.com/150";
          final title = news["title"] ?? "No title";
          final source = news["source"]?["name"] ?? "Unknown source";

          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
                ),
              ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(source),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePage() => const ProfilePage();
  Widget _buildAIAssistantPage() => AIAssistantPage(articles: articles);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildNewsPage(),
      _buildProfilePage(),
      _buildAIAssistantPage(),
    ];

    final List<String> titles = [
      "Top Headlines",
      "Profile",
      "AI Assistant",
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),

      body: pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "AI Assistant",
          ),
        ],
      ),
    );
  }
}
