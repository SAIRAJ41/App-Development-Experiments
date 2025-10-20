import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HistoryScreen.dart'; // Make sure you have this file for the history screen

class Btn {
  static const String del = "D";
  static const String clr = "C";
  static const String per = "%";

  // Use standard operators for logic
  static const String multiply = "*";
  static const String divide = "/";

  static const String add = "+";
  static const String subtract = "-";
  static const String calculate = "=";
  static const String dot = ".";

  static const String n0 = "0";
  static const String n1 = "1";
  static const String n2 = "2";
  static const String n3 = "3";
  static const String n4 = "4";
  static const String n5 = "5";
  static const String n6 = "6";
  static const String n7 = "7";
  static const String n8 = "8";
  static const String n9 = "9";

  static const List<String> buttonValues = [
    del,
    clr,
    per,
    multiply,
    n7,
    n8,
    n9,
    divide,
    n4,
    n5,
    n6,
    subtract,
    n1,
    n2,
    n3,
    add,
    n0,
    dot,
    calculate,
  ];
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String number1 = "";
  String operand = "";
  String number2 = "";

  String lastExpression = "";
  String lastResult = "";
  bool isCalculated = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    String currentInput = "$number1$operand$number2";

    // Use the display-friendly version for the current input text
    String displayInput = currentInput
        .replaceAll(Btn.multiply, "×")
        .replaceAll(Btn.divide, "÷");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.orange),
            onPressed: _navigateToHistory,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- DISPLAY AREA ---
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 1. Top Right (Small) - Shows the last expression
                      Text(
                        // Show display-friendly symbols in history
                        isCalculated
                            ? lastExpression
                                  .replaceAll(Btn.multiply, "×")
                                  .replaceAll(Btn.divide, "÷")
                            : "",
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 2. Middle Right (Medium) - Shows the last result
                      Text(
                        isCalculated && lastResult.isNotEmpty ? lastResult : "",
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // 3. Bottom Right (Largest) - Shows current input OR final result
                      SingleChildScrollView(
                        reverse: true,
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          isCalculated
                              ? lastResult
                              : displayInput.isEmpty
                              ? "0"
                              : displayInput,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- KEYPAD ---
            const Divider(color: Colors.white24, height: 1),
            Wrap(
              children: Btn.buttonValues
                  .map(
                    (value) => SizedBox(
                      width: value == Btn.n0
                          ? screenSize.width / 2
                          : screenSize.width / 4,
                      height: screenSize.width / 5,
                      child: buildButton(value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String value) {
    // Map logical operators to display symbols
    final displayValue = {Btn.multiply: "×", Btn.divide: "÷"}[value] ?? value;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: getBtnColor(value),
        shape: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () =>
              onBtnTap(value), // Logic uses the real operator (e.g., "*")
          child: Center(
            child: Text(
              displayValue, // UI shows the pretty symbol (e.g., "×")
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onBtnTap(String value) {
    if (value == Btn.del) {
      delete();
      return;
    }
    if (value == Btn.clr) {
      clearAll();
      return;
    }
    if (value == Btn.per) {
      convertToPercentage();
      return;
    }
    if (value == Btn.calculate) {
      calculate();
      return;
    }
    appendValue(value);
  }

  // --- THIS IS THE MODIFIED FUNCTION ---
  Future<void> calculate() async {
    if (number1.isEmpty || operand.isEmpty) return;
    if (number2.isEmpty) number2 = number1;

    double num1 = double.tryParse(number1) ?? 0;
    double num2 = double.tryParse(number2) ?? 0;
    double result = 0;

    String currentExpression = "$number1$operand$number2";

    switch (operand) {
      case Btn.add:
        result = num1 + num2;
        break;
      case Btn.subtract:
        result = num1 - num2;
        break;
      case Btn.multiply: // Checks for "*"
        result = num1 * num2;
        break;
      case Btn.divide: // Checks for "/"
        if (num2 == 0) {
          setState(() {
            lastExpression = currentExpression;
            number1 = "Error";
            operand = "";
            number2 = "";
            lastResult = "Division by zero";
            isCalculated = true;
          });
          return;
        }
        result = num1 / num2;
        break;
      default:
        return;
    }

    String formattedResult = result
        .toStringAsFixed(10)
        .replaceAll(RegExp(r"0*$"), "");
    if (formattedResult.endsWith('.')) {
      formattedResult = formattedResult.substring(
        0,
        formattedResult.length - 1,
      );
    }

    // --- FIX: ---
    // 1. Update the UI *immediately* first. Do not wait for the database.
    setState(() {
      lastExpression = currentExpression; // e.g., "1*3"
      lastResult = formattedResult; // e.g., "3"
      number1 = formattedResult; // Keep result for chaining
      operand = "";
      number2 = "";
      isCalculated = true; // This tells the UI to show the result screen
    });
    // --- END FIX ---

    // 2. Now, try to save to Firestore in the background.
    // Use try-catch so the app doesn't crash if this fails.
    try {
      await _firestore.collection('calculator_history').add({
        'expression': currentExpression,
        'result': formattedResult,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log the error (optional)
      print("Error saving to Firestore: $e");
    }
  }

  void convertToPercentage() {
    if (number2.isNotEmpty) {
      double num = double.tryParse(number2) ?? 0;
      setState(() {
        number2 = "${num / 100}";
      });
    } else if (number1.isNotEmpty) {
      double num = double.tryParse(number1) ?? 0;
      setState(() {
        number1 = "${num / 100}";
      });
    }

    setState(() {
      lastExpression = "";
      lastResult = "";
      isCalculated = false;
    });
  }

  void clearAll() {
    setState(() {
      number1 = "";
      operand = "";
      number2 = "";
      lastExpression = "";
      lastResult = "";
      isCalculated = false;
    });
  }

  void delete() {
    if (isCalculated) {
      clearAll();
      return;
    }

    if (number2.isNotEmpty) {
      number2 = number2.substring(0, number2.length - 1);
    } else if (operand.isNotEmpty) {
      operand = "";
    } else if (number1.isNotEmpty) {
      number1 = number1.substring(0, number1.length - 1);
    }

    setState(() {});
  }

  void appendValue(String value) {
    bool isOperator =
        (value != Btn.dot &&
        int.tryParse(value) == null &&
        value != Btn.calculate);

    if (isCalculated) {
      if (isOperator) {
        // User wants to chain calculation (e.g., "4 + 2")
        setState(() {
          lastExpression = "";
          lastResult = "";
          isCalculated = false;
        });
      } else {
        // User wants to start a new calculation (e.g., "4" then "9")
        setState(() {
          number1 = "";
          lastExpression = "";
          lastResult = "";
          isCalculated = false;
        });
      }
    }

    if (isOperator) {
      if (number1.isEmpty) return;

      if (operand.isNotEmpty && number2.isNotEmpty) {
        calculate();
      }

      setState(() {
        operand = value;
      });
    } else {
      // It's a number or dot
      if (operand.isEmpty) {
        // Inputting number1
        if (value == Btn.dot && number1.contains(Btn.dot)) return;
        if (value == Btn.dot && number1.isEmpty) value = "0.";
        setState(() {
          number1 += value;
        });
      } else {
        // Inputting number2
        if (value == Btn.dot && number2.contains(Btn.dot)) return;
        if (value == Btn.dot && number2.isEmpty) value = "0.";
        setState(() {
          number2 += value;
        });
      }
    }
  }

  Color getBtnColor(String value) {
    return [Btn.del, Btn.clr].contains(value)
        ? Colors.blueGrey
        : [
            Btn.per,
            Btn.multiply,
            Btn.add,
            Btn.subtract,
            Btn.divide,
            Btn.calculate,
          ].contains(value)
        ? Colors.orange
        : Colors.black87;
  }

  void _navigateToHistory() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HistoryScreen()));
  }
}
