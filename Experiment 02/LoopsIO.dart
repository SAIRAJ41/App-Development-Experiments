import 'dart:io';
void main() {
  //Taking input from user
  stdout.write("Enter your name: ");  // Ask user for name
  String? name = stdin.readLineSync(); // Read user input (String)

  //Printing output
  print("Hello, $name! "); // Print greeting

  //For loop example
  print("\n--For Loop Example--");
  print("Numbers from 1 to 5:");
  for (int i = 1; i <= 5; i++) {
    print(i); // Print numbers 1, 2, 3, 4, 5
  }

  //While loop example
  print("\n--While Loop Example--");
  print("Enter a number to start countdown:");
  int number = int.parse(stdin.readLineSync()!); // Convert input to int

  while (number > 0) {
    print(number); // Print current number
    number--;      // Decrease number by 1
  }

  print("Countdown Finished!"); // Indicate end of countdown
}
