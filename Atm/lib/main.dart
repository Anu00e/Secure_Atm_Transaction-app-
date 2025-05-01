import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() => runApp(ATMApp());

class ATMApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ATMHomePage(),
    );
  }
}

class ATMHomePage extends StatefulWidget {
  @override
  _ATMHomePageState createState() => _ATMHomePageState();
}

class _ATMHomePageState extends State<ATMHomePage> {
  final TextEditingController accountNumberController = TextEditingController();
  String predefinedLocation = "Begambur, Dindigul";
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    initializeSocket();
  }

  void initializeSocket() {
    // Initialize the socket connection to the server
    socket = IO.io(
      'http://127.0.0.1:5000/atm',
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport
          .disableAutoConnect()
          .build(),
    );

    // Connect the socket
    socket.connect();

    // Listen for the connection confirmation
    socket.onConnect((_) {
      print("Connected to the ATM namespace.");
    });

    // Listen for the transaction_status event and redirect to MessageScreen
    socket.on("transaction_status", (data) {
      print("Transaction Status Update: $data");
      String message = data["message"] ?? "No message received.";
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(message: message),
        ),
      );
    });

    // Handle disconnection
    socket.onDisconnect((_) {
      print("Disconnected from the server.");
    });
  }

  Future<void> sendAccountNumber() async {
    final String accountNumber = accountNumberController.text;

    if (accountNumber.isEmpty) {
      showMessage("Please enter an account number.");
      return;
    }

    // Validate account number with the server
    final validationUrl = Uri.parse('http://127.0.0.1:5000/atm/validate_account');

    try {
      final validationResponse = await http.post(
        validationUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"account_number": accountNumber}),
      );

      if (validationResponse.statusCode == 200) {
        final data = jsonDecode(validationResponse.body);
        if (data["valid"] == false) {
          showMessage("Account number invalid.");
          return;
        } else {
          // Proceed with the transaction request if account is valid
          final url = Uri.parse('http://127.0.0.1:5000/atm/request_transaction');
          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "account_number": accountNumber,
              "location": predefinedLocation,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            showMessage(data["message"]);
          } else {
            final data = jsonDecode(response.body);
            showMessage(data["message"] ?? "Transaction failed.");
          }
        }
      } else {
        final data = jsonDecode(validationResponse.body);
        showMessage(data["message"] ?? "Error validating account.");
      }
    } catch (e) {
      showMessage("Failed to connect to the server. Please try again.");
      print("Error in sending account number: $e");
    }
  }

  void showMessage(String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(message: message),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the socket connection when the widget is destroyed
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ATM App"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: accountNumberController,
              decoration: InputDecoration(
                labelText: "Enter Account Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendAccountNumber,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  final String message;

  MessageScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Message"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


