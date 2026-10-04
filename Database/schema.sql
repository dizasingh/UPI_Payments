CREATE DATABASE upi_simulator;

USE upi_simulator;
CREATE TABLE npci (
    npci_id INT PRIMARY KEY AUTO_INCREMENT,
    network_name VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE banks (
    bank_id INT PRIMARY KEY AUTO_INCREMENT,
    bank_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(10) NOT NULL UNIQUE,
    npci_id INT NOT NULL,
    FOREIGN KEY (npci_id) REFERENCES npci(npci_id)
);

CREATE TABLE psps (
    psp_id INT PRIMARY KEY AUTO_INCREMENT,
    psp_name VARCHAR(100) NOT NULL,
    npci_id INT NOT NULL,
    FOREIGN KEY (npci_id) REFERENCES npci(npci_id)
);
SHOW TAbles;
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bank_id INT NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (bank_id) REFERENCES banks(bank_id)
);
Show Tables;
CREATE TABLE upi_accounts (
    upi_account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bank_account_id INT NOT NULL,
    upi_id VARCHAR(100) NOT NULL UNIQUE,
    upi_pin VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(account_id)
);
CREATE TABLE psp_users (
    psp_user_id INT PRIMARY KEY AUTO_INCREMENT,
    psp_id INT NOT NULL,
    user_id INT NOT NULL,
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (psp_id) REFERENCES psps(psp_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),

    UNIQUE (psp_id, user_id)
);
SHow Tables;
CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    method_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
);
CREATE TABLE transaction_status (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    status_name VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(255)
);
CREATE TABLE beneficiaries (
    beneficiary_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    beneficiary_upi_id VARCHAR(100) NOT NULL,
    nickname VARCHAR(50),
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);
SHow Tables;
CREATE TABLE transactions (
    transaction_id VARCHAR(30) PRIMARY KEY,
    payer_upi_id INT NOT NULL,
    payee_upi_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method_id INT NOT NULL,
    status_id INT NOT NULL,
    transaction_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    remarks VARCHAR(255),

    FOREIGN KEY (payer_upi_id)
        REFERENCES upi_accounts(upi_account_id),

    FOREIGN KEY (payee_upi_id)
        REFERENCES upi_accounts(upi_account_id),

    FOREIGN KEY (payment_method_id)
        REFERENCES payment_methods(payment_method_id),

    FOREIGN KEY (status_id)
        REFERENCES transaction_status(status_id),

    CHECK (amount > 0)
);
SHow Tables;
INSERT INTO npci (network_name, description)
VALUES ('UPI', 'Unified Payments Interface network');
INSERT INTO banks (bank_name, bank_code, npci_id)
VALUES
('ICICI Bank', 'ICIC', 1),
('HDFC Bank', 'HDFC', 1),
('State Bank of India', 'SBIN', 1),
('YES Bank', 'YESB', 1),
('Axis Bank', 'UTIB', 1);
INSERT INTO psps (psp_name, npci_id)
VALUES ('PayFlow', 1);
INSERT INTO payment_methods (method_name, description)
VALUES
('UPI ID', 'Payment using a UPI ID'),
('QR Code', 'Payment using a QR code'),
('Mobile Number', 'Payment using a registered mobile number');
INSERT INTO transaction_status (status_name, description)
VALUES
('PENDING', 'Transaction is being processed'),
('SUCCESS', 'Transaction completed successfully'),
('FAILED', 'Transaction failed'),
('REFUNDED', 'Amount has been refunded');
SELECT * FROM npci;
SELECT * FROM banks;
SELECT * FROM psps;
SELECT * FROM payment_methods;
SELECT * FROM transaction_status;
INSERT INTO users
(full_name, phone, email, password)
VALUES
('Rahul Sharma', '9876543210', 'rahul@gmail.com', 'rahul123');
SELECT * FROM users;
SELECT user_id, full_name FROM users;
SELECT bank_id, bank_name FROM banks;
INSERT INTO bank_accounts
(user_id, bank_id, account_number, balance, account_status)
VALUES
(1, 1, '100012345678', 10000.00, 'ACTIVE');
SELECT * FROM bank_accounts;
INSERT INTO upi_accounts
(user_id, bank_account_id, upi_id, upi_pin, status)
VALUES
(1, 1, 'rahul@payflow', '1234', 'ACTIVE');
SELECT * FROM upi_accounts;
INSERT INTO psp_users
(psp_id, user_id)
VALUES
(1, 1);
SELECT * FROM psp_users;
INSERT INTO users
(full_name, phone, email, password)
VALUES
('Priya Sharma', '9876543211', 'priya@gmail.com', 'priya123');
SELECT user_id, full_name, phone, email
FROM users;
INSERT INTO bank_accounts
(user_id, bank_id, account_number, balance, account_status)
VALUES
(2, 2, '200012345678', 5000.00, 'ACTIVE');
SELECT * FROM bank_accounts;
INSERT INTO upi_accounts
(user_id, bank_account_id, upi_id, upi_pin, status)
VALUES
(2, 2, 'priya@payflow', '5678', 'ACTIVE');
SELECT * FROM upi_accounts;
INSERT INTO psp_users
(psp_id, user_id)
VALUES
(1, 2);
SELECT * FROM psp_users;
SELECT
    u.user_id,
    u.full_name,
    b.bank_name,
    ba.account_number,
    ba.balance,
    ua.upi_id,
    p.psp_name
FROM users u
JOIN bank_accounts ba
    ON u.user_id = ba.user_id
JOIN banks b
    ON ba.bank_id = b.bank_id
JOIN upi_accounts ua
    ON u.user_id = ua.user_id
JOIN psp_users pu
    ON u.user_id = pu.user_id
JOIN psps p
    ON pu.psp_id = p.psp_id;
    START TRANSACTION;
    SELECT account_id, balance
FROM bank_accounts
WHERE account_id = 1;
UPDATE bank_accounts
SET balance = balance - 500
WHERE account_id = 1
  AND balance >= 500;
  SELECT account_id, balance
FROM bank_accounts
WHERE account_id = 1;
UPDATE bank_accounts
SET balance = balance + 500
WHERE account_id = 2;
SELECT account_id, balance
FROM bank_accounts
WHERE account_id IN (1, 2);
INSERT INTO transactions
(
    transaction_id,
    payer_upi_id,
    payee_upi_id,
    amount,
    payment_method_id,
    status_id,
    remarks
)
VALUES
(
    'TXN0001',
    1,
    2,
    500.00,
    1,
    2,
    'Payment from Rahul to Priya'
);
SELECT * FROM transactions;
COMMIT;
START TRANSACTION;
UPDATE bank_accounts
SET balance = balance - 20000
WHERE account_id = 1
  AND balance >= 20000;
  SELECT account_id, balance
  ROLLBACK;
FROM bank_accounts
WHERE account_id IN (1, 2);
SELECT account_id, balance

FROM bank_accounts
WHERE account_id IN (1, 2);
ROLLBACK;
SELECT account_id, balance
FROM bank_accounts
WHERE account_id IN (1, 2);
INSERT INTO transactions
(
    transaction_id,
    payer_upi_id,
    payee_upi_id,
    amount,
    payment_method_id,
    status_id,
    remarks
)
VALUES
(
    'TXN0002',
    1,
    2,
    20000.00,
    1,
    3,
    'Payment failed - insufficient balance'
);
SELECT * FROM transactions;
