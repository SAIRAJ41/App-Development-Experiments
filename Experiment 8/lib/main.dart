import 'package:flutter/material.dart';

// --- MAIN FUNCTION ---
void main() {
  runApp(const MyApp());
}

// ----------------------------------------------------
// MODEL CLASS for To-Do Items
// ----------------------------------------------------
class Task {
  String title;
  bool isDone;

  Task(this.title, this.isDone);
}

// ----------------------------------------------------
// 1. Tab Screen Content WIDGETS (Tab 1, 2, and 3)
// ----------------------------------------------------

// Widget for the Home Screen content (Tab 1)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 80, color: Colors.indigo),
          SizedBox(height: 10),
          Text(
            'Welcome Home!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This is the main content area for the Home Tab. Use the tab bar above and the drawer on the left.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for the To-Do List Screen content (Tab 2) - NEW IMPLEMENTATION
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // Initial list of tasks
  final List<Task> _tasks = [
    Task('Implement Tab Navigation', true),
    Task('Add Drawer Menu', true),
    Task('Replace Feed with To-Do List', false),
    Task('Test Dismissible Functionality', false),
  ];
  final TextEditingController _taskController = TextEditingController();

  // Function to add a new task
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(_taskController.text, false));
      });
      _taskController.clear();
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  // Function to toggle task completion status
  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
  }

  // Function to delete a task
  void _deleteTask(int index) {
    final taskTitle = _tasks[index].title;
    setState(() {
      _tasks.removeAt(index);
    });
    
    // Provide user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "$taskTitle" deleted!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Function to show the Add Task dialog
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addTask(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _taskController.clear();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main list content
        _tasks.isEmpty
            ? const Center(
                child: Text(
                  'No tasks yet! Tap the "+" button to add one.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Dismissible(
                    // Unique key is required for Dismissible
                    key: Key(task.title + index.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteTask(index);
                    },
                    // Background shown when item is swiped
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? Colors.grey : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        leading: Checkbox(
                          value: task.isDone,
                          onChanged: (val) => _toggleTask(index),
                          activeColor: Colors.teal,
                        ),
                        trailing: const Icon(Icons.swipe_left, color: Colors.grey, size: 16),
                        onTap: () => _toggleTask(index),
                      ),
                    ),
                  );
                },
              ),
        
        // Floating Action Button for adding tasks, aligned to bottom-right
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 6,
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        )
      ],
    );
  }
}


// Widget for the Settings Screen content (Tab 3)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'App Preferences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[700]),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Account Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Notification Preferences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Privacy & Security'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Dark Mode'),
          secondary: const Icon(Icons.dark_mode_outlined),
          value: false, // Placeholder for actual state
          onChanged: (bool value) {},
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 2. Drawer Navigation Destination Functions (Navigate to a new Page/Scaffold)
// ----------------------------------------------------

// Function to build and navigate to the Profile Page
void _navigateToProfilePage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Colors.deepOrange,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.deepOrangeAccent,
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'User Name',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text('Navigated via Drawer', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      ),
    ),
  );
}

// Function to build and navigate to the About Page
void _navigateToAboutPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('About App'),
          backgroundColor: Colors.blueGrey,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 80, color: Colors.blueGrey),
                SizedBox(height: 16),
                Text(
                  'Navigation App Demo v1.0',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'This application showcases the integration of both Tab-based navigation and Drawer (sidebar) navigation in a single Flutter structure.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ----------------------------------------------------
// 3. Main Navigation Screen (Assembling Tabs and Drawer)
// ----------------------------------------------------

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController is necessary to manage the TabBar state.
    return DefaultTabController(
      length: 3, // Number of tabs: Home, To-Do, Settings
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dual Navigation Demo'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 4,
          // TabBar is typically placed at the bottom of the AppBar for top tabs
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.check_box), text: 'To-Do'), // UPDATED
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),

        // Implementation of Drawer Navigation
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.teal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'App Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Navigation Options',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  // Close the drawer before navigating
                  Navigator.pop(context);
                  // Call the dedicated function to navigate
                  _navigateToProfilePage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  // Close the drawer before navigating
                  Navigator.pop(context);
                  // Call the dedicated function to navigate
                  _navigateToAboutPage(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () {
                  // Simple action: just close the drawer
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

        // Implementation of Tab-based Navigation (The content views)
        body: const TabBarView(
          children: [
            // Now using the dedicated Widget classes:
            HomeScreen(),
            TodoListScreen(), // UPDATED
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. Root App Widget
// ----------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(), // Set the main screen with navigation
    );
  }
} 