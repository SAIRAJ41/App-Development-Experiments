import { Ionicons } from "@expo/vector-icons";
import { Checkbox } from "expo-checkbox";
import { useEffect, useState } from "react";
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

// 🔥 1. FIREBASE CORE IMPORTS (Ensure 'app' is imported for Auth)
import { getAuth, onAuthStateChanged, signInAnonymously, User } from "firebase/auth"; // Auth Imports
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDocs,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  writeBatch
} from "firebase/firestore";
import { app, db } from '../../constants/firebaseConfig';

// Initialize Auth
const auth = getAuth(app);

// 🔥 UPDATED ToDoType: 'id' must be string, and we need userId
type ToDoType = {
  id: string; // Firestore uses string IDs
  title: string;
  isDone: boolean;
  userId: string; // Required for secure rules (even with public ones, it's best practice)
  createdAt?: Timestamp;
};

export default function Index() {
  const [todos, setTodos] = useState<ToDoType[]>([]);
  const [todoText, setTodoText] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [originalTodos, setOriginalTodos] = useState<ToDoType[]>([]);

  // 🔥 AUTH & LOADING STATES
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true); // Combined loading state
  const [filter, setFilter] = useState<"all" | "done" | "active">("all");

  // 1. AUTHENTICATION (Signs in user and gets UID)
  useEffect(() => {
    // Listen for Auth state changes
    const unsubscribeAuth = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        setUser(currentUser);
        // Don't set loading=false yet; wait for the data listener
      } else {
        // No user found, sign in anonymously
        signInAnonymously(auth)
          .then((userCredential) => {
            setUser(userCredential.user);
          })
          .catch((error) => {
            console.error("Anonymous Sign-In Failed:", error);
            setLoading(false); // Stop loading if auth fails
          });
      }
    });

    return () => unsubscribeAuth();
  }, []); // Run once on component mount

  // 2. REAL-TIME DATA LISTENER (READ OPERATION)
  useEffect(() => {
    if (!user) {
      setLoading(true);
      return; // Wait until the user is authenticated
    }

    // Query for tasks belonging to the current user (if security rules enforce it)
    const todosCollection = collection(db, "todos");
    const q = query(todosCollection, orderBy("createdAt", "desc"));
    // You'd ideally add a where('userId', '==', user.uid) filter here for clean UI

    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const fetchedTodos: ToDoType[] = [];
      querySnapshot.forEach((documentSnapshot) => {
        // Only show items that have the userId field for safety, or you might need a cast here
        const data = documentSnapshot.data() as Omit<ToDoType, "id">;
        fetchedTodos.push({
          id: documentSnapshot.id,
          ...data,
        });
      });

      setOriginalTodos(fetchedTodos);
      setLoading(false); // Stop loading after data is fetched

    }, (error) => {
      console.error("Firestore Listener Error: ", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user]); // Run whenever the 'user' object is set/changes

  // 3. ADD TODO (CREATE OPERATION)
  const addTodo = async () => {
    // ⚠️ CRITICAL CHECK: Block write if the user hasn't been signed in yet
    if (todoText.trim() === "" || !user) {
      console.warn("Cannot add todo: User not authenticated or input is empty.");
      return;
    }

    try {
      await addDoc(collection(db, "todos"), {
        title: todoText.trim(),
        isDone: false,
        createdAt: serverTimestamp(),
        userId: user.uid, // 🔥 CRITICAL FIX: Include userId
      });
      setTodoText("");
      Keyboard.dismiss();
    } catch (error) {
      console.error("Error adding document to Firestore: ", error);
    }
  };

  // 4. DELETE TODO (DELETE OPERATION)
  const deleteTodo = async (id: string) => {
    if (!user) return;
    try {
      await deleteDoc(doc(db, "todos", id));
    } catch (error) {
      console.error("Error deleting document from Firestore: ", error);
    }
  };

  // 5. DELETE ALL TODOS (Using batch for efficiency)
  const deleteAllTodos = async () => {
    if (!user) return;
    try {
      const todosRef = collection(db, "todos");
      // Query to get all user's todos (must enforce security rules here too)
      const q = query(todosRef);
      const snapshot = await getDocs(q);

      const batch = writeBatch(db);
      snapshot.docs.forEach((d) => {
        batch.delete(d.ref);
      });

      await batch.commit();
    } catch (error) {
      console.error("Error deleting all documents: ", error);
    }
  };

  // 6. HANDLE DONE (UPDATE OPERATION)
  const handleDone = async (id: string, currentStatus: boolean) => {
    if (!user) return;
    try {
      await updateDoc(doc(db, "todos", id), {
        isDone: !currentStatus,
      });
    } catch (error) {
      console.error("Error updating document: ", error);
    }
  };

  const onSearch = (query: string) => { setSearchQuery(query); };
  const onFilter = (selectedFilter: "all" | "done" | "active") => { setFilter(selectedFilter); };

  // 7. FILTERING/SEARCHING EFFECT
  useEffect(() => {
    let filteredList = originalTodos;
    if (searchQuery !== "") {
      filteredList = filteredList.filter((todo) =>
        todo.title.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    if (filter === "done") {
      filteredList = filteredList.filter((todo) => todo.isDone);
    } else if (filter === "active") {
      filteredList = filteredList.filter((todo) => !todo.isDone);
    }
    setTodos(filteredList);
  }, [searchQuery, filter, originalTodos]);

  const displayedTodos = todos;

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>Authenticating and Loading Tasks...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => {
            alert("This could open a side menu!");
          }}
        >
          <Ionicons name="menu" size={24} color={"#333"} />
        </TouchableOpacity>
        <TouchableOpacity onPress={deleteAllTodos}>
          <Ionicons name="trash-bin" size={24} color={"red"} />
        </TouchableOpacity>
      </View>

      <View style={styles.searchBar}>
        <Ionicons name="search" size={24} color={"#333"} />
        <TextInput
          placeholder="Search"
          value={searchQuery}
          onChangeText={onSearch}
          style={styles.searchInput}
          clearButtonMode="always"
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity onPress={() => setSearchQuery("")}>
            <Ionicons name="close-circle" size={24} color="#999" />
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterButton, filter === "all" && styles.activeFilter]}
          onPress={() => onFilter("all")}
        >
          <Text style={styles.filterText}>All</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterButton, filter === "done" && styles.activeFilter]}
          onPress={() => onFilter("done")}
        >
          <Text style={styles.filterText}>Done</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.filterButton,
            filter === "active" && styles.activeFilter,
          ]}
          onPress={() => onFilter("active")}
        >
          <Text style={styles.filterText}>Active</Text>
        </TouchableOpacity>
      </View>

      {displayedTodos.length === 0 && originalTodos.length > 0 && (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>No matching tasks found!</Text>
        </View>
      )}
      {originalTodos.length === 0 && !loading && (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>No tasks found! 🎉</Text>
        </View>
      )}

      <FlatList
        data={displayedTodos}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <ToDoItem
            todo={item}
            deleteTodo={deleteTodo}
            handleDone={() => handleDone(item.id, item.isDone)}
          />
        )}
      />

      <KeyboardAvoidingView
        style={styles.footer}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={Platform.OS === "ios" ? 10 : 0}
      >
        <TextInput
          placeholder="Add New ToDo"
          value={todoText}
          onChangeText={(text) => setTodoText(text)}
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

// ToDoItem component (no changes needed here beyond previous fixes)
const ToDoItem = ({
  todo,
  deleteTodo,
  handleDone,
}: {
  todo: ToDoType;
  deleteTodo: (id: string) => void;
  handleDone: () => void;
}) => (
  <View style={styles.todoContainer}>
    <View style={styles.todoInfoContainer}>
      <Checkbox
        value={todo.isDone}
        onValueChange={handleDone}
        color={todo.isDone ? "#4630EB" : undefined}
      />
      <Text
        style={[
          styles.todoText,
          todo.isDone && { textDecorationLine: "line-through" },
        ]}
      >
        {todo.title}
      </Text>
    </View>
    <TouchableOpacity
      onPress={() => {
        deleteTodo(todo.id);
      }}
    >
      <Ionicons name="trash" size={24} color={"red"} />
    </TouchableOpacity>
  </View>
);

// Styles (unchanged)
const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: 20, backgroundColor: "#f5f5f5" },
  header: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 },
  searchBar: { flexDirection: "row", backgroundColor: "#fff", alignItems: 'center', paddingHorizontal: 16, paddingVertical: Platform.OS === 'ios' ? 16 : 8, borderRadius: 10, gap: 10, marginBottom: 20 },
  searchInput: { flex: 1, fontSize: 16, color: "#333" },
  filterContainer: { flexDirection: 'row', justifyContent: 'space-around', marginBottom: 20, backgroundColor: '#fff', borderRadius: 10, padding: 5 },
  filterButton: { paddingVertical: 10, paddingHorizontal: 20, borderRadius: 8 },
  activeFilter: { backgroundColor: '#4630EB' },
  filterText: { color: '#333', fontWeight: 'bold' },
  todoContainer: { flexDirection: "row", justifyContent: "space-between", backgroundColor: "#fff", padding: 16, borderRadius: 10, marginBottom: 20 },
  todoInfoContainer: { flexDirection: "row", gap: 10, alignItems: "center" },
  todoText: { fontSize: 16, color: "#333" },
  footer: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 20 },
  newTodoInput: { flex: 1, backgroundColor: "#fff", padding: 16, borderRadius: 10, fontSize: 16, color: "#333" },
  addButton: { backgroundColor: "#4630EB", padding: 8, borderRadius: 10, marginLeft: 20 },
  emptyContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  emptyText: { fontSize: 18, color: '#999' },
});