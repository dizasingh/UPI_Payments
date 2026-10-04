USE upi_simulator;

-- 1. UPI Network
INSERT INTO npci (network_name, description)
VALUES ('UPI', 'Unified Payments Interface network');

-- 2. Banks
INSERT INTO banks (bank_name, bank_code, npci_id)
VALUES
('ICICI Bank', 'ICIC', 1),
('HDFC Bank', 'HDFC', 1),
('State Bank of India', 'SBIN', 1),
('YES Bank', 'YESB', 1),
('Axis Bank', 'UTIB', 1);

-- 3. Your simulated PSP
INSERT INTO psps (psp_name, npci_id)
VALUES ('PayFlow', 1);

-- 4. Payment methods
INSERT INTO payment_methods (method_name, description)
VALUES
('UPI ID', 'Payment using a UPI ID'),
('QR Code', 'Payment using a QR code'),
('Mobile Number', 'Payment using a registered mobile number');

-- 5. Transaction statuses
INSERT INTO transaction_status (status_name, description)
VALUES
('PENDING', 'Transaction is being processed'),
('SUCCESS', 'Transaction completed successfully'),
('FAILED', 'Transaction failed'),
('REFUNDED', 'Amount has been refunded');

-- 6. Rahul
INSERT INTO users
(full_name, phone, email, password)
VALUES
('Rahul Sharma', '9876543210', 'rahul@gmail.com', 'rahul123');

-- 7. Priya
INSERT INTO users
(full_name, phone, email, password)
VALUES
('Priya Sharma', '9876543211', 'priya@gmail.com', 'priya123');

-- 8. Rahul's ICICI account
INSERT INTO bank_accounts
(user_id, bank_id, account_number, balance, account_status)
VALUES
(1, 1, '100012345678', 9500.00, 'ACTIVE');

-- 9. Priya's HDFC account
INSERT INTO bank_accounts
(user_id, bank_id, account_number, balance, account_status)
VALUES
(2, 2, '200012345678', 5500.00, 'ACTIVE');

-- 10. Rahul's UPI account
INSERT INTO upi_accounts
(user_id, bank_account_id, upi_id, upi_pin, status)
VALUES
(1, 1, 'rahul@payflow', '1234', 'ACTIVE');

-- 11. Priya's UPI account
INSERT INTO upi_accounts
(user_id, bank_account_id, upi_id, upi_pin, status)
VALUES
(2, 2, 'priya@payflow', '5678', 'ACTIVE');

-- 12. Connect Rahul to PayFlow
INSERT INTO psp_users
(psp_id, user_id)
VALUES
(1, 1);

-- 13. Connect Priya to PayFlow
INSERT INTO psp_users
(psp_id, user_id)
VALUES
(1, 2);

-- 14. Successful transaction
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

-- 15. Failed transaction
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