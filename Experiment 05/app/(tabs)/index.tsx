import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  Keyboard,
  StyleSheet,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";

/* ================================
   🧩 PURE LOGIC FUNCTIONS (testable)
================================ */
export type Todo = {
  id: number;
  title: string;
  isDone: boolean;
};

export const addTodoLogic = (todos: Todo[], text: string): Todo[] => {
  if (!text.trim()) return todos;
  const newTodo: Todo = { id: Date.now(), title: text, isDone: false };
  return [newTodo, ...todos];
};

export const deleteTodoLogic = (todos: Todo[], id: number): Todo[] => {
  return todos.filter((t) => t.id !== id);
};

export const toggleDoneLogic = (todos: Todo[], id: number): Todo[] => {
  return todos.map((t) =>
    t.id === id ? { ...t, isDone: !t.isDone } : t
  );
};

/* ================================
   🧠 MAIN COMPONENT
================================ */
const ToDoListApp: React.FC = () => {
  const [todoText, setTodoText] = useState<string>("");
  const [todos, setTodos] = useState<Todo[]>([]);

  useEffect(() => {
    (async () => {
      const saved = await AsyncStorage.getItem("my-todo");
      if (saved) setTodos(JSON.parse(saved));
    })();
  }, []);

  const saveTodos = async (data: Todo[]) => {
    await AsyncStorage.setItem("my-todo", JSON.stringify(data));
  };

  const addTodo = async () => {
    const updated = addTodoLogic(todos, todoText);
    setTodos(updated);
    await saveTodos(updated);
    setTodoText("");
    Keyboard.dismiss();
  };

  const deleteTodo = async (id: number) => {
    const updated = deleteTodoLogic(todos, id);
    setTodos(updated);
    await saveTodos(updated);
  };

  const toggleDone = async (id: number) => {
    const updated = toggleDoneLogic(todos, id);
    setTodos(updated);
    await saveTodos(updated);
  };

  const renderItem = ({ item }: { item: Todo }) => (
    <View style={styles.todoItem}>
      <TouchableOpacity onPress={() => toggleDone(item.id)}>
        <Text style={[styles.todoText, item.isDone && styles.done]}>
          {item.title}
        </Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={() => deleteTodo(item.id)}>
        <Text style={styles.deleteBtn}>❌</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.heading}>📝 To-Do List</Text>
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          value={todoText}
          onChangeText={setTodoText}
          placeholder="Enter task..."
        />
        <TouchableOpacity onPress={addTodo} style={styles.addBtn}>
          <Text style={styles.btnText}>ADD</Text>
        </TouchableOpacity>
      </View>
      <FlatList
        data={todos}
        renderItem={renderItem}
        keyExtractor={(item) => item.id.toString()}
      />
    </View>
  );
};

/* ================================
   🎨 STYLES
================================ */
const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, backgroundColor: "#f7f7f7" },
  heading: { fontSize: 24, fontWeight: "bold", marginBottom: 10 },
  inputRow: { flexDirection: "row", marginBottom: 10 },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 10,
  },
  addBtn: {
    marginLeft: 8,
    backgroundColor: "#4caf50",
    borderRadius: 8,
    justifyContent: "center",
    paddingHorizontal: 15,
  },
  btnText: { color: "#fff", fontWeight: "bold" },
  todoItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 10,
    marginBottom: 5,
    backgroundColor: "#fff",
    borderRadius: 8,
  },
  todoText: { fontSize: 16 },
  done: { textDecorationLine: "line-through", color: "#888" },
  deleteBtn: { color: "red", fontSize: 18 },
});

export default ToDoListApp;
