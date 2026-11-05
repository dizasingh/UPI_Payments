# UPI Payments Simulator

A full-stack UPI payment simulation application developed using Flutter, Python Flask, and MySQL. The project demonstrates the working of a UPI-based payment system through user authentication, beneficiary management, payee resolution, and transaction processing.

## Features

- **User Registration & Login:** Allows users to register and securely log in.
- **Email OTP Verification:** Verifies users through email-based OTP authentication.
- **Bank Integration (Simulation):** Retrieves available banks and Payment Service Providers (PSPs).
- **Beneficiary Management:** Allows users to add and manage beneficiaries.
- **Payee Resolution:** Resolves recipient details before initiating a payment.
- **Payment Processing:** Simulates UPI transactions between users.
- **Transaction History:** Maintains records of payment transactions.
- **QR Code Payments:** Supports QR-code-based payment functionality.

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Python Flask |
| Database | MySQL |
| API Communication | HTTP / REST APIs |
| Development Tools | VS Code, Git, GitHub |

## Database Design

The project uses a relational MySQL database named `upi_simulator`.

The database consists of the following tables:

- `npci`
- `banks`
- `psps`
- `users`
- `bank_accounts`
- `upi_accounts`
- `beneficiaries`
- `payment_methods`
- `psp_users`
- `transaction_status`
- `transactions`

These tables represent users, banking relationships, UPI accounts, beneficiaries, payment methods, and transaction records.

## Application Architecture

The application follows a three-layer architecture:

1. **Frontend:** Flutter provides the user interface and handles user interactions.
2. **Backend:** Flask handles authentication, payment operations, business logic, and API requests.
3. **Database:** MySQL stores user information, bank details, beneficiaries, and transaction records.

### Application Flow

```text
        Flutter Frontend
               |
               | HTTP Requests
               |
          Flask Backend
               |
          MySQL Database
               |
       Transaction Processing
               |
        Response to Flutter
```

## Project Structure

```text
UPI_Payments/
│
├── frontend/
│   ├── lib/
│   ├── android/
│   └── pubspec.yaml
│
├── backend/
│   ├── app.py
│   ├── .env
│   └── requirements.txt
│
├── database/
│   └── schema.sql
│
└── README.md
```

*Note: Adjust the folder names above to match your actual repository structure.*

## Setup and Installation

### Prerequisites

- Python
- Flutter SDK
- MySQL Server
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/dizasingh/UPI_Payments.git
cd UPI_Payments
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Configure your database credentials and other required environment variables in a `.env` file.

Start the Flask server:

```bash
python app.py
```

### 3. Database Setup

- Start MySQL Server.
- Create the `upi_simulator` database.
- Execute the SQL schema to create the required tables.
- Configure the database credentials in the backend environment file.

### 4. Frontend Setup

Navigate to the Flutter frontend directory:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Learning Outcomes

- Understanding relational database design and table relationships.
- Implementing CRUD operations using MySQL.
- Connecting a Flutter frontend with a Flask backend.
- Working with HTTP requests and backend API endpoints.
- Understanding user authentication and OTP verification.
- Simulating payment processing and maintaining transaction records.

## Disclaimer

This project is developed for academic and educational purposes. It simulates UPI payment workflows and does not connect to actual banking networks or process real financial transactions.
