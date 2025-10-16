const readline = require("readline");

// Setup input/output interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// Utility function to ask question with Promise (cleaner than nested callbacks)
function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

let items = []; // Array for CRUD operations

// CREATE
function create(item) {
  item = item.trim();
  if (!item) {
    console.log("⚠️ Cannot add empty item.");
    return;
  }
  items.push(item);
  console.log(`✅ Added: ${item}`);
}

// READ
function read() {
  if (!items.length) {
    console.log("📋 No items found.");
  } else {
    console.log("📋 Current Items:");
    items.forEach((item, i) => console.log(`${i}: ${item}`));
  }
}

// UPDATE
function update(index, newValue) {
  if (isNaN(index) || index < 0 || index >= items.length) {
    console.log("⚠️ Update failed: Invalid index.");
    return;
  }
  newValue = newValue.trim();
  if (!newValue) {
    console.log("⚠️ New value cannot be empty.");
    return;
  }
  console.log(`✏️ Updated: ${items[index]} -> ${newValue}`);
  items[index] = newValue;
}

// DELETE
function remove(index) {
  if (isNaN(index) || index < 0 || index >= items.length) {
    console.log("⚠️ Delete failed: Invalid index.");
    return;
  }
  console.log(`🗑️ Removed: ${items[index]}`);
  items.splice(index, 1);
}

// MENU
async function showMenu() {
  console.log("\n--- CRUD Menu ---");
  console.log("1. Create");
  console.log("2. Read");
  console.log("3. Update");
  console.log("4. Delete");
  console.log("5. Exit");

  const choice = await ask("Choose an option: ");

  switch (choice.trim()) {
    case "1":
      const item = await ask("Enter item to add: ");
      create(item);
      break;
    case "2":
      read();
      break;
    case "3":
      read();
      const uIndex = await ask("Enter index to update: ");
      const newValue = await ask("Enter new value: ");
      update(parseInt(uIndex), newValue);
      break;
    case "4":
      read();
      const dIndex = await ask("Enter index to delete: ");
      remove(parseInt(dIndex));
      break;
    case "5":
      console.log("👋 Exiting...");
      rl.close();
      process.exit(0);
    default:
      console.log("⚠️ Invalid choice, try again.");
  }

  showMenu(); // Show menu again after action
}

// Start program
showMenu();
