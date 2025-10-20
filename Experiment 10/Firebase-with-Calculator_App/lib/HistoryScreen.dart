import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Clear All History',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('calculator_history').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No history yet. Perform some calculations!",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final history = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final expression = item['expression'] ?? '';
              final result = item['result'] ?? '';

              return ListTile(
                title: Text(
                  expression,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                subtitle: Text(
                  "= $result",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Delete all history
  void _clearAllHistory() async {
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
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('calculator_history').get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared!')),
        );
      }
    }
  }
}
