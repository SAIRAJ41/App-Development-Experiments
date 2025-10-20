import {
  FlatList,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import Checkbox from "expo-checkbox";
import { useEffect, useState } from "react";
import * as SQLite from "expo-sqlite";

// Type for tasks
type ToDoType = {
  id: number;
  title: string;
  isDone: boolean;
};

// Open or create SQLite database
const db = SQLite.openDatabaseSync("todo.db");

export default function Index() {
  const [todos, setTodos] = useState<ToDoType[]>([]);
  const [todoText, setTodoText] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [filter, setFilter] = useState<"all" | "done" | "active">("all");

  // Create table once when component mounts
  useEffect(() => {
    db.execAsync(`
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER DEFAULT 0
      );
    `).then(loadTodos);
  }, []);

  // Load all todos
  const loadTodos = async () => {
    const result = await db.getAllAsync<ToDoType>("SELECT * FROM todos ORDER BY id DESC;");
    setTodos(result);
  };

  // Add new todo
  const addTodo = async () => {
    if (todoText.trim() === "") return;
    await db.runAsync("INSERT INTO todos (title, isDone) VALUES (?, 0);", [todoText]);
    setTodoText("");
    Keyboard.dismiss();
    await loadTodos();
  };

  // Delete one todo
  const deleteTodo = async (id: number) => {
    await db.runAsync("DELETE FROM todos WHERE id = ?;", [id]);
    await loadTodos();
  };

  // Delete all todos
  const deleteAllTodos = async () => {
    await db.runAsync("DELETE FROM todos;");
    await loadTodos();
  };

  // Toggle completion
  const handleDone = async (id: number, isDone: boolean) => {
    const newStatus = isDone ? 0 : 1;
    await db.runAsync("UPDATE todos SET isDone = ? WHERE id = ?;", [newStatus, id]);
    await loadTodos();
  };

  // Filtered list based on search + filter state
  const filteredTodos = todos.filter((todo) => {
    const matchesSearch = todo.title.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter =
      filter === "all" ||
      (filter === "done" && todo.isDone) ||
      (filter === "active" && !todo.isDone);
    return matchesSearch && matchesFilter;
  });

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => alert("This could open a side menu!")}>
          <Ionicons name="menu" size={24} color={"#333"} />
        </TouchableOpacity>
        <TouchableOpacity onPress={deleteAllTodos}>
          <Ionicons name="trash-bin" size={24} color={"red"} />
        </TouchableOpacity>
      </View>

      {/* Search bar */}
      <View style={styles.searchBar}>
        <Ionicons name="search" size={24} color={"#333"} />
        <TextInput
          placeholder="Search"
          value={searchQuery}
          onChangeText={setSearchQuery}
          style={styles.searchInput}
          clearButtonMode="always"
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity onPress={() => setSearchQuery("")}>
            <Ionicons name="close-circle" size={24} color="#999" />
          </TouchableOpacity>
        )}
      </View>

      {/* Filter buttons */}
      <View style={styles.filterContainer}>
        {["all", "done", "active"].map((f) => (
          <TouchableOpacity
            key={f}
            style={[styles.filterButton, filter === f && styles.activeFilter]}
            onPress={() => setFilter(f as any)}
          >
            <Text style={styles.filterText}>{f.toUpperCase()}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Empty state */}
      {filteredTodos.length === 0 && (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>No tasks found! 🎉</Text>
        </View>
      )}

      {/* Todo List */}
      <FlatList
        data={filteredTodos}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <ToDoItem todo={item} deleteTodo={deleteTodo} handleDone={handleDone} />
        )}
      />

      {/* Input section */}
      <KeyboardAvoidingView
        style={styles.footer}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <TextInput
          placeholder="Add New ToDo"
          value={todoText}
          onChangeText={setTodoText}
          style={styles.newTodoInput}
          autoCorrect={false}
          onSubmitEditing={addTodo}
        />
        <TouchableOpacity style={styles.addButton} onPress={addTodo}>
          <Ionicons name="add" size={34} color={"#fff"} />
        </TouchableOpacity>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const ToDoItem = ({
  todo,
  deleteTodo,
  handleDone,
}: {
  todo: ToDoType;
  deleteTodo: (id: number) => void;
  handleDone: (id: number, isDone: boolean) => void;
}) => (
  <View style={styles.todoContainer}>
    <View style={styles.todoInfoContainer}>
      <Checkbox
        value={!!todo.isDone}
        onValueChange={() => handleDone(todo.id, !!todo.isDone)}
        color={todo.isDone ? "#4630EB" : undefined}
      />
      <Text
        style={[styles.todoText, todo.isDone && { textDecorationLine: "line-through" }]}
      >
        {todo.title}
      </Text>
    </View>
    <TouchableOpacity onPress={() => deleteTodo(todo.id)}>
      <Ionicons name="trash" size={24} color={"red"} />
    </TouchableOpacity>
  </View>
);

const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: 20, backgroundColor: "#f5f5f5" },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  searchBar: {
    flexDirection: "row",
    backgroundColor: "#fff",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingVertical: Platform.OS === "ios" ? 16 : 8,
    borderRadius: 10,
    gap: 10,
    marginBottom: 20,
  },
  searchInput: { flex: 1, fontSize: 16, color: "#333" },
  filterContainer: {
    flexDirection: "row",
    justifyContent: "space-around",
    marginBottom: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 5,
  },
  filterButton: { paddingVertical: 10, paddingHorizontal: 20, borderRadius: 8 },
  activeFilter: { backgroundColor: "#4630EB" },
  filterText: { color: "#333", fontWeight: "bold" },
  todoContainer: {
    flexDirection: "row",
    justifyContent: "space-between",
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 10,
    marginBottom: 20,
  },
  todoInfoContainer: { flexDirection: "row", gap: 10, alignItems: "center" },
  todoText: { fontSize: 16, color: "#333" },
  footer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 20,
  },
  newTodoInput: {
    flex: 1,
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 10,
    fontSize: 16,
    color: "#333",
  },
  addButton: {
    backgroundColor: "#4630EB",
    padding: 8,
    borderRadius: 10,
    marginLeft: 20,
  },
  emptyContainer: { flex: 1, justifyContent: "center", alignItems: "center" },
  emptyText: { fontSize: 18, color: "#999" },
});
