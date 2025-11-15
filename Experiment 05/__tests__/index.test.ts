import React from "react";
import renderer from "react-test-renderer";
// Mock AsyncStorage (prevents native module errors)
jest.mock("@react-native-async-storage/async-storage", () => ({
  setItem: jest.fn(),
  getItem: jest.fn(),
  removeItem: jest.fn(),
}));
//Add a new To-Do item
const addTodo = (todos: TodoItem[], title: string): TodoItem[] => {
  const trimmed = title.trim();
  if (trimmed === "") return todos;
  const newTodo: TodoItem = {
    id: Date.now(),
    title: trimmed,
    isDone: false,
  };
  return [newTodo, ...todos];
};
//Delete a To-Do by ID
const deleteTodo = (todos: TodoItem[], id: number): TodoItem[] =>
  todos.filter((t) => t.id !== id);
//Toggle completion state
const toggleDone = (todos: TodoItem[], id: number): TodoItem[] =>
  todos.map((t) =>
    t.id === id ? { ...t, isDone: !t.isDone } : t
  );
interface TodoItem {
  id: number;
  title: string;
  isDone: boolean;
}
describe("🧪 To-Do List Logic Tests", () => {
  it("adds a new todo", () => {
    const todos: TodoItem[] = [];
    const updated = addTodo(todos, "Learn Jest");
    expect(updated.length).toBe(1);
    expect(updated[0].title).toBe("Learn Jest");
    expect(updated[0].isDone).toBe(false);
  });
  it("does not add an empty todo", () => {
    const todos: TodoItem[] = [];
    const updated = addTodo(todos, "   ");
    expect(updated.length).toBe(0);
  });
  it("deletes a todo by id", () => {
    const todos: TodoItem[] = [{ id: 1, title: "Task", isDone: false }];
    const updated = deleteTodo(todos, 1);
    expect(updated.length).toBe(0);
  });
  it("toggles done status correctly", () => {
    const todos: TodoItem[] = [{ id: 1, title: "Task", isDone: false }];
    const updated = toggleDone(todos, 1);
    expect(updated[0].isDone).toBe(true);
  });
});
