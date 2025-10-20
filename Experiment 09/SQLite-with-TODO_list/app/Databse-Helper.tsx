// Database.ts
import * as SQLite from "expo-sqlite";

export type ToDoType = {
  id: number;
  title: string;
  isDone: number;
};
export const db: any = (SQLite as any).openDatabase("todo.db");

export const createTable = () => {
  db.transaction((tx: any) => {
    tx.executeSql(
      `CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER DEFAULT 0
      );`
    );
  });
};

export const getTodos = (callback: (todos: ToDoType[]) => void) => {
  db.transaction((tx: any) => {
    tx.executeSql(
      "SELECT * FROM todos ORDER BY id DESC;",
      [],
      (_tx: any, result: any) => callback(result.rows._array),
      (_tx: any, error: any) => {
        console.log("Error fetching todos:", error);
        return true;
      }
    );
  });
};

export const addTodo = (title: string, callback?: () => void) => {
  db.transaction((tx: any) => {
    tx.executeSql("INSERT INTO todos (title, isDone) VALUES (?, 0);", [title], () =>
      callback?.()
    );
  });
};

export const deleteTodo = (id: number, callback?: () => void) => {
  db.transaction((tx: any) => {
    tx.executeSql("DELETE FROM todos WHERE id = ?;", [id], () => callback?.());
  });
};

export const toggleTodo = (id: number, isDone: number, callback?: () => void) => {
  db.transaction((tx: any) => {
    tx.executeSql("UPDATE todos SET isDone = ? WHERE id = ?;", [isDone, id], () =>
      callback?.()
    );
  });
};
