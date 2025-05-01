from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
socketio = SocketIO(app, cors_allowed_origins="*")
CORS(app)

# Mock database
database = {
    "123456": {"name": "John Doe", "mobile": "9876543210", "pin": "4321"},
}

# Store transaction details temporarily
pending_transactions = {}

@app.route('/atm/validate_account', methods=['POST'])
def validate_account():
    data = request.get_json()
    account_number = data.get("account_number")

    # Check if account exists in the database
    if account_number in database:
        return jsonify({"valid": True})
    else:
        return jsonify({"valid": False, "message": "Account number is invalid."}), 404

@app.route('/atm/request_transaction', methods=['POST'])
def atm_request_transaction():
    data = request.get_json()
    account_number = data.get("account_number")
    location = data.get("location")

    # Log the received data
    print(f"ATM Request: Account {account_number}, Location {location}")

    # Check if account exists in the database
    if account_number not in database:
        return jsonify({"status": "error", "message": "Account not found"}), 404

    # Store location temporarily
    pending_transactions[account_number] = {"location": location, "status": "pending"}

    # Emit location confirmation request to FinanceApp
    socketio.emit('location_confirmation', {
        "account_number": account_number,
        "location": location
    }, namespace='/finance')

    return jsonify({"status": "success", "message": "Account found, waiting for location confirmation."})

@socketio.on('location_response', namespace='/finance')
def handle_location_response(data):
    print(f"Location Response Received: {data}")

    account_number = data.get("account_number")
    user_response = data.get("response")  # Yes or No
    pin = data.get("pin")
    amount_limit = data.get("amount_limit")

    if account_number not in pending_transactions:
        emit("error", {"message": "No pending transaction for this account."}, namespace='/finance')
        return

    # If user response is "No"
    if user_response.lower() == "no":
        message = "Transaction failed: cardholder declined withdrawal request."
        socketio.emit("transaction_status", {
            "account_number": account_number,
            "message": message
        }, namespace='/finance')
        socketio.emit("transaction_status", {
            "account_number": account_number,
            "message": message
        }, namespace='/atm')  # Send to ATM interface
        pending_transactions.pop(account_number, None)
        return

    # Validate PIN
    account_data = database.get(account_number)
    if account_data["pin"] != pin:
        message = "Transaction failed: Invalid PIN."
        socketio.emit("transaction_status", {
            "account_number": account_number,
            "message": message
        }, namespace='/finance')
        socketio.emit("transaction_status", {
            "account_number": account_number,
            "message": message
        }, namespace='/atm')  # Send to ATM interface
        return

    # If all validations pass, transaction is successful
    message = f"Transaction successful! Amount limit: {amount_limit}"
    socketio.emit("transaction_status", {
        "account_number": account_number,
        "message": message
    }, namespace='/finance')  # Send to Finance app
    socketio.emit("transaction_status", {
        "account_number": account_number,
        "message": message
    }, namespace='/atm')  # Send to ATM interface
    pending_transactions.pop(account_number, None)

@socketio.on('connect', namespace='/finance')
def handle_finance_connect():
    print("Finance app connected")
    emit('message', {"message": "Connected to server"}, namespace='/finance')

@socketio.on('disconnect', namespace='/finance')
def handle_finance_disconnect():
    print("Finance app disconnected")

@socketio.on('connect', namespace='/atm')
def handle_atm_connect():
    print("ATM interface connected")
    emit('message', {"message": "Connected to server"}, namespace='/atm')

@socketio.on('disconnect', namespace='/atm')
def handle_atm_disconnect():
    print("ATM interface disconnected")

if __name__ == '__main__':
    socketio.run(app, debug=True)