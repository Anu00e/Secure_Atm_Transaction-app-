# 💳 Secure ATM Transaction System

This project simulates a secure ATM transaction system built with **Flutter and Python** (Socket.IO). It contains three interconnected applications:

1.**ATM Interface** – For user withdrawals and PIN verification.

2.**Safe Swipe App** – For card ownership verification and secure linking.

3.**Python Backend Server** – Manages user authentication, card linking, and transaction validation using Socket.IO.

---

## 🧱 Project Structure
Secure_Atm_Transaction(app)/ 
      ├── Atm/  **ATM User Interface (Flutter App)**
      ├── safe_swipe/ **Safe Swipe Mobile App (Flutter App)** 
      └── server/ **Python Backend with Socket.IO**

---

## 📱 Components Overview

### 🔐 1. ATM Interface (Flutter)
- Simulates ATM machine UI.
- User enters card details and PIN.
- Communicates with Python backend via Socket.IO.

### 📲 2. Safe Swipe App (Flutter)
- Verifies and links user’s bank card.
- OTP-based login for security.
- Real-time approval of transactions.

### 🐍 3. Backend Server (Python + Socket.IO)
- Handles real-time communication between ATM and Safe Swipe.
- Validates user identity and card ownership.
- Approves or denies transactions securely.

---

## 🚀 How to Run

### Prerequisites:
- Flutter SDK
- Python 3.x
- Android Emulator / Device
- `python-socketio` and Flask

---

## License  
This project is licensed under the Apache License 2.0 - see the [LICENSE](./LICENSE) file for details.  
You can also view it online at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

---

### Backend (Python):
```bash
cd server
pip install flask flask-socketio
python app.py


