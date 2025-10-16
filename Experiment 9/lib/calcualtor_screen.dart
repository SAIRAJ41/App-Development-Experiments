import 'package:flutter/material.dart';
import 'Database_Helper.dart';
import 'HistoryScreen.dart'; // Import the new screen

class Btn {
  static const String del = "D";
  static const String clr = "C";
  static const String per = "%";
  static const String multiply = "×";
  static const String divide = "÷";
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
  String number1 = ""; // . 0-9
  String operand = ""; // + - * /
  String number2 = ""; // . 0-9
  
  // State variables for the last completed calculation (to show history above input)
  String lastExpression = ""; 
  String lastResult = ""; 

  @override
  void initState() {
    super.initState();
  }

  // Method to navigate to the separate HistoryScreen
  void _navigateToHistory() async {
    // Pushes the HistoryScreen onto the navigation stack
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      // Added AppBar for the History button
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.orange),
            tooltip: 'View History',
            onPressed: _navigateToHistory,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Display Area (Last Calculation + Current Input)
            Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                // Wrap the Column with an Align widget
                // This ensures the Column itself takes up all available width
                // so its contents can align fully to the right.
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    // The crossAxisAlignment is what aligns the children of the column (the Text widgets)
                    // to the end (right) of the column's horizontal space.
                    crossAxisAlignment: CrossAxisAlignment.end, 
                    children: [
                      // LAST EXPRESSION (History above present equation)
                      Text(
                        lastExpression,
                        // Set TextAlign.end to ensure the text itself aligns to the right
                        textAlign: TextAlign.end, 
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // LAST RESULT (History above present equation)
                      Text(
                        lastResult,
                        // Set TextAlign.end
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // CURRENT INPUT/RESULT
                      // To make the SingleChildScrollView align to the right, we wrap it in a Row
                      // and use a Spacer to push it to the end.
                      Row(
                        children: [
                          const Spacer(), // Pushes the following widget to the right
                          Expanded(
                            child: SingleChildScrollView(
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                "$number1$operand$number2".isEmpty
                                    ? "0"
                                    : "$number1$operand$number2",
                                // Set TextAlign.end
                                textAlign: TextAlign.end, 
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // buttons
            Wrap(
              children: Btn.buttonValues
                  .map(
                    (value) => SizedBox(
                      width: value == Btn.n0
                          ? screenSize.width / 2
                          : (screenSize.width / 4),
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

  Widget buildButton(value) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () => onBtnTap(value),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ########
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

  // ##############
  // EDITED calculate() to save to DB and update the last expression/result display
  void calculate() async {
    if (number1.isEmpty) return;
    if (operand.isEmpty) return;
    if (number2.isEmpty) return;

    // Get the full expression before calculation
    final String currentExpression = "$number1$operand$number2";

    final double num1 = double.parse(number1);
    final double num2 = double.parse(number2);

    var result = 0.0;
    switch (operand) {
      case Btn.add:
        result = num1 + num2;
        break;
      case Btn.subtract:
        result = num1 - num2;
        break;
      case Btn.multiply:
        result = num1 * num2;
        break;
      case Btn.divide:
        if (num2 == 0) {
          // Handle division by zero
          setState(() {
            number1 = "Error";
            operand = "";
            number2 = "";
            lastExpression = currentExpression; // Show the expression that caused error
            lastResult = "Error";
          });
          return;
        }
        result = num1 / num2;
        break;
      default:
    }

    // Format the result
    String formattedResult = result.toStringAsFixed(
      10,
    ); // Use a high precision for safety
    if (formattedResult.contains('.')) {
      formattedResult = formattedResult.replaceAll(
        RegExp(r"0*$"),
        "",
      ); // Remove trailing zeros
      if (formattedResult.endsWith('.')) {
        formattedResult = formattedResult.substring(
          0,
          formattedResult.length - 1,
        ); // Remove trailing dot
      }
    }

    // Save to DB (must be awaited since it's an async call)
    await DatabaseHelper.instance.insertHistory(
      currentExpression,
      formattedResult,
    );

    // Update the calculator state
    setState(() {
      lastExpression = currentExpression; // Move the expression to history view
      lastResult = formattedResult; // Move the result to history view
      number1 = formattedResult; // Set the result as the new current number
      operand = "";
      number2 = "";
    });
  }

  // ##############
  // converts output to %
  void convertToPercentage() {
    // ex: 434+324
    if (number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty) {
      // calculate before conversion
      calculate();
    }

    if (operand.isNotEmpty) {
      // cannot be converted
      return;
    }

    final number = double.parse(number1);
    setState(() {
      number1 = "${(number / 100)}";
      operand = "";
      number2 = "";
      // Reset the last history display when starting a new calculation chain
      lastExpression = ""; 
      lastResult = "";
    });
  }

  // ##############
  // clears all output
  void clearAll() {
    setState(() {
      number1 = "";
      operand = "";
      number2 = "";
      // Reset the last history display when clearing
      lastExpression = "";
      lastResult = "";
    });
  }

  // ##############
  // delete one from the end
  void delete() {
    if (number2.isNotEmpty) {
      // 12323 => 1232
      number2 = number2.substring(0, number2.length - 1);
    } else if (operand.isNotEmpty) {
      operand = "";
    } else if (number1.isNotEmpty) {
      number1 = number1.substring(0, number1.length - 1);
    }

    setState(() {});
  }

  // #############
  // appends value to the end
  void appendValue(String value) {
    // if is operand and not "."
    if (value != Btn.dot && int.tryParse(value) == null) {
      // operand pressed
      if (operand.isNotEmpty && number2.isNotEmpty) {
        // calculate the equation before assigning new operand
        calculate();
      }
      operand = value;
    }
    // assign value to number1 variable
    else if (number1.isEmpty || operand.isEmpty) {
      // check if value is "." | ex: number1 = "1.2"
      if (value == Btn.dot && number1.contains(Btn.dot)) return;
      if (value == Btn.dot && (number1.isEmpty || number1 == Btn.n0)) {
        // ex: number1 = "" | "0"
        value = "0.";
      }
      number1 += value;
    }
    // assign value to number2 variable
    else if (number2.isEmpty || operand.isNotEmpty) {
      // check if value is "." | ex: number1 = "1.2"
      if (value == Btn.dot && number2.contains(Btn.dot)) return;
      if (value == Btn.dot && (number2.isEmpty || number2 == Btn.n0)) {
        // number1 = "" | "0"
        value = "0.";
      }
      number2 += value;
    }

    setState(() {});
  }

  // ########
  Color getBtnColor(value) {
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
}