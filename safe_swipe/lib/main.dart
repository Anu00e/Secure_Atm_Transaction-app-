import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(FinanceApp());

class FinanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: FinanceHomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  @override
  _FinanceHomePageState createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  late IO.Socket socket;
  String message = "Waiting for location confirmation...";
  String accountNumber = "";
  String location = "";
  bool showApprovalForm = false;
  bool showPinForm = false;
  bool showReceipt = false;
  String transactionId = "";
  String withdrawnAmount = "";

  final TextEditingController pinController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    socket = IO.io('http://127.0.0.1:5000/finance', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => setState(() => message = "Connected to server."));

    socket.on('location_confirmation', (data) {
      setState(() {
        accountNumber = data['account_number'];
        location = data['location'];
        message = "Confirm withdrawal at $location?";
        showApprovalForm = true;
      });
    });

    socket.on('transaction_status', (data) {
      print("Transaction Status Received: $data");

      setState(() {
        showApprovalForm = false;
        showPinForm = false;

        if (data['message'].contains("Transaction successful!")) {
          transactionId = uuid.v4();
          withdrawnAmount = data['amount_limit'] ?? amountController.text;
          amountController.clear();
          pinController.clear();
          showReceipt = true;
          message = "Withdrawal Successful!";
        } else {
          message = "You declined withdrawal request";
        }
      });
    });
  }

  void sendApprovalResponse(bool approve) {
    if (approve) {
      setState(() {
        showApprovalForm = false;
        showPinForm = true;
        message = "Enter Amount & PIN.";
      });
    } else {
      socket.emit('location_response', {
        'account_number': accountNumber,
        'response': "No",
      });
      setState(() {
        message = "Transaction Denied.";
        showApprovalForm = false;
      });
    }
  }

  void sendPinAndAmount() {
    if (pinController.text.isEmpty || amountController.text.isEmpty) {
      setState(() => message = "Please enter both amount and PIN.");
      return;
    }

    socket.emit('location_response', {
      'account_number': accountNumber,
      'response': "Yes",
      'pin': pinController.text,
      'amount_limit': amountController.text,
    });

    setState(() {
      message = "Transaction in progress...";
      showPinForm = false;
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade900, Colors.amber.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Safe Swipe ATM",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Lottie.asset('assets/transaction.json', height: 150),
                  SizedBox(height: 20),
                  Text(
                    message,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  if (showApprovalForm) _approvalButtons(),
                  if (showPinForm) _pinForm(),
                  if (showReceipt) _transactionReceipt(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => sendApprovalResponse(true),
          child: Text("Approve"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        ElevatedButton(
          onPressed: () => sendApprovalResponse(false),
          child: Text("Deny"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _pinForm() {
    return Column(
      children: [
        TextField(controller: amountController, decoration: InputDecoration(labelText: "Enter Amount")),
        TextField(controller: pinController, decoration: InputDecoration(labelText: "Enter PIN"), obscureText: true),
        SizedBox(height: 20),
        ElevatedButton(onPressed: sendPinAndAmount, child: Text("Submit")),
      ],
    );
  }

  Widget _transactionReceipt() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Withdrawal Receipt", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Divider(),
            Text("Transaction ID: $transactionId"),
            Text("Withdrawn Amount: $withdrawnAmount"),
            Text("Location: $location"),
          ],
        ),
      ),
    );
  }
}
