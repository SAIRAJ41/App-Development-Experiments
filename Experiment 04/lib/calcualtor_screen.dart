import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // The main display text is correctly set to the combined state variables
    String displayText = "$number1$operand$number2";
    
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // output
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    // Display current expression/result, or "0" if empty
                    displayText.isEmpty ? "0" : displayText,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ),

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
              // Added color for visibility
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
      calculate(); // This is where the calculation happens
      return;
    }

    appendValue(value);
  }

  // ##############
  // calculates the result
  void calculate() {
    // FIX 1: Use double.tryParse to safely handle number conversion
    final double? num1 = double.tryParse(number1);
    final double? num2 = double.tryParse(number2);

    // Ensure all components are valid before calculation
    if (num1 == null || operand.isEmpty || num2 == null) return;

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
          });
          return;
        }
        result = num1 / num2;
        break;
      default:
        return;
    }

    // FIX 2: Robust result formatting to remove trailing zeros and dot
    String formattedResult = result.toString();
    
    // Check if the result is an integer (e.g., 2.0)
    if (formattedResult.contains('.')) {
        // Use a regular expression to trim trailing zeros and dot if it's the last character
        formattedResult = formattedResult.replaceAll(RegExp(r"0*$"), "");
        if (formattedResult.endsWith('.')) {
            formattedResult = formattedResult.substring(0, formattedResult.length - 1);
        }
    }
    
    // If the result is too long, use a fixed precision for display
    if (formattedResult.length > 12) {
        formattedResult = result.toStringAsExponential(5);
    }
    
    // FIX 3: Update state to show the result in number1
    setState(() {
      number1 = formattedResult;
      operand = "";
      number2 = "";
    });
  }

  // ##############
  // converts output to %
  void convertToPercentage() {
    if (number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty) {
      calculate();
    }

    if (operand.isNotEmpty) {
      return; // Cannot convert if an operation is pending
    }

    // Use tryParse to prevent errors on invalid string
    final number = double.tryParse(number1);
    if (number == null) return;

    setState(() {
      // Robust percentage formatting
      String percentResult = (number / 100).toString();
      
      if (percentResult.contains('.')) {
        percentResult = percentResult.replaceAll(RegExp(r"0*$"), "");
        if (percentResult.endsWith('.')) {
            percentResult = percentResult.substring(0, percentResult.length - 1);
        }
      }
      
      number1 = percentResult;
      operand = "";
      number2 = "";
    });
  }

  // ##############
  // clears all output
  void clearAll() {
    setState(() {
      number1 = "";
      operand = "";
      number2 = "";
    });
  }

  // ##############
  // delete one from the end
  void delete() {
    if (number2.isNotEmpty) {
      number2 = number2.substring(0, number2.length - 1);
    } else if (operand.isNotEmpty) {
      operand = "";
    } else if (number1.isNotEmpty) {
      // FIX: Handle "Error" state by clearing everything if delete is pressed
      if (number1 == "Error") {
          clearAll();
          return;
      }
      number1 = number1.substring(0, number1.length - 1);
    }

    setState(() {});
  }

  // #############
  // appends value to the end
  void appendValue(String value) {
    bool isOperator = (value != Btn.dot && int.tryParse(value) == null && value != Btn.calculate);

    // If an operator is pressed
    if (isOperator) {
      // If a full expression is ready (e.g., 5+5), calculate it first
      if (number1.isNotEmpty && operand.isNotEmpty && number2.isNotEmpty) {
        calculate();
        // number1 now holds the result, which the new operator will use
      }
      
      // Only set the operand if number1 is not empty/Error
      if (number1.isNotEmpty && number1 != "Error") {
          operand = value;
      }
    }
    // Assign value to number1
    else if (number1.isEmpty || operand.isEmpty) {
      // Clear Error state if a number is pressed
      if (number1 == "Error") number1 = "";
      
      // Check for multiple dots
      if (value == Btn.dot && number1.contains(Btn.dot)) return;
      
      // Prepend "0" for dot if necessary
      if (value == Btn.dot && (number1.isEmpty || number1 == Btn.n0)) {
        value = "0.";
      }
      
      // Prevent leading zero
      if (number1 == "0" && value != Btn.dot) {
          number1 = value;
      } else {
          number1 += value;
      }
    }
    // Assign value to number2
    else if (operand.isNotEmpty) {
      // Check for multiple dots
      if (value == Btn.dot && number2.contains(Btn.dot)) return;
      
      // Prepend "0" for dot if necessary
      if (value == Btn.dot && (number2.isEmpty || number2 == Btn.n0)) {
        value = "0.";
      }
      
      // Prevent leading zero
      if (number2 == "0" && value != Btn.dot) {
          number2 = value;
      } else {
          number2 += value;
      }
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