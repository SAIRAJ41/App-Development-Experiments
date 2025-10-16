import 'package:flutter/material.dart';
import 'Database_Helper.dart'; // Ensure this path is correct

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  // IMPORTANT: The key to making the delete button work is having
  // DatabaseHelper.instance.clearHistory() implemented in your Database_Helper.dart
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Load history from the database
  void _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    // This call requires DatabaseHelper.instance.getHistory() to exist
    final history = await DatabaseHelper.instance.getHistory();
    setState(() {
      _history = history.reversed.toList(); // Display newest first
      _isLoading = false;
    });
  }

  // Delete all history records
  void _clearAllHistory() async {
    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete all calculation history? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // This line is causing the error because clearHistory() is likely undefined
      await DatabaseHelper.instance.clearHistory(); 
      _loadHistory(); // Reloads the empty list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: 'Clear All History',
              onPressed: _clearAllHistory,
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    "No history yet. Perform some calculations!",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return ListTile(
                      title: Text(
                        item['expression'],
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      subtitle: Text(
                        "= ${item['result']}",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
