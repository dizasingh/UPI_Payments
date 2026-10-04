from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import os
import uuid
from decimal import Decimal, InvalidOperation
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()

app = Flask(__name__)
CORS(app)


# ============================================================
# DATABASE
# ============================================================

def get_db():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )


def get_cursor(db):
    return db.cursor(dictionary=True, buffered=True)


# ============================================================
# HELPERS
# ============================================================

def get_status_id(cursor, status_name):
    cursor.execute("""
        SELECT status_id
        FROM transaction_status
        WHERE status_name = %s
        LIMIT 1
    """, (status_name,))

    row = cursor.fetchone()

    if not row:
        raise ValueError(
            f"Transaction status '{status_name}' is not configured"
        )

    return row["status_id"]


def get_payment_method_id(cursor, method_name):
    cursor.execute("""
        SELECT payment_method_id
        FROM payment_methods
        WHERE method_name = %s
        LIMIT 1
    """, (method_name,))

    row = cursor.fetchone()

    if not row:
        raise ValueError(
            f"Payment method '{method_name}' is not configured"
        )

    return row["payment_method_id"]


def generate_transaction_id(cursor):
    while True:
        transaction_id = "TXN" + uuid.uuid4().hex[:12].upper()

        cursor.execute("""
            SELECT transaction_id
            FROM transactions
            WHERE transaction_id = %s
        """, (transaction_id,))

        if cursor.fetchone() is None:
            return transaction_id


def find_user_payment_account(cursor, identifier, lock=False):

    lock_sql = " FOR UPDATE" if lock else ""

    query = f"""
        SELECT
            u.user_id,
            u.full_name,
            u.phone,
            u.email,

            ua.upi_account_id,
            ua.upi_id,
            ua.upi_pin,
            ua.status AS upi_status,
            ua.bank_account_id,

            ba.account_id,
            ba.account_number,
            ba.balance,
            ba.account_status,

            b.bank_id,
            b.bank_name,
            b.bank_code,

            pu.psp_user_id,
            psp.psp_id,
            psp.psp_name,
            psp.npci_id,

            n.network_name,
            n.description AS network_description

        FROM users u

        JOIN upi_accounts ua
            ON u.user_id = ua.user_id

        JOIN bank_accounts ba
            ON ua.bank_account_id = ba.account_id

        JOIN banks b
            ON ba.bank_id = b.bank_id

        JOIN psp_users pu
            ON u.user_id = pu.user_id

        JOIN psps psp
            ON pu.psp_id = psp.psp_id

        JOIN npci n
            ON psp.npci_id = n.npci_id

        WHERE
            ua.upi_id = %s
            OR u.phone = %s

        LIMIT 1
        {lock_sql}
    """

    cursor.execute(query, (identifier, identifier))

    return cursor.fetchone()


def validate_payment_account(account, role):

    if not account:
        raise ValueError(f"{role} account not found")

    if account["upi_status"] != "ACTIVE":
        raise ValueError(f"{role} UPI account is inactive")

    if account["account_status"] != "ACTIVE":
        raise ValueError(f"{role} bank account is inactive")

    if not account["psp_id"]:
        raise ValueError(f"{role} PSP relationship not found")

    if not account["npci_id"]:
        raise ValueError(f"{role} NPCI relationship not found")

    if not account["network_name"]:
        raise ValueError(f"{role} NPCI network not found")


# ============================================================
# HOME
# ============================================================

@app.route("/")
def home():
    return "UPI Payment Simulator Backend is running!"


# ============================================================
# TEST DATABASE
# ============================================================

@app.route("/test-db")
def test_db():

    db = None
    cursor = None

    try:
        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("SELECT COUNT(*) AS total_users FROM users")

        result = cursor.fetchone()

        return jsonify({
            "success": True,
            "users": result["total_users"]
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# GET BANKS
# ============================================================

@app.route("/api/banks", methods=["GET"])
def get_banks():

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                bank_id,
                bank_name,
                bank_code,
                npci_id
            FROM banks
            ORDER BY bank_name
        """)

        banks = cursor.fetchall()

        return jsonify({
            "success": True,
            "banks": banks
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# GET PSPS
# ============================================================

@app.route("/api/psps", methods=["GET"])
def get_psps():

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                p.psp_id,
                p.psp_name,
                p.npci_id,
                n.network_name
            FROM psps p
            JOIN npci n
                ON p.npci_id = n.npci_id
            ORDER BY p.psp_name, p.psp_id
        """)

        psps = cursor.fetchall()

        return jsonify({
            "success": True,
            "psps": psps
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# GET PAYMENT METHODS
# ============================================================

@app.route("/api/payment-methods", methods=["GET"])
def get_payment_methods():

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                payment_method_id,
                method_name,
                description
            FROM payment_methods
            ORDER BY payment_method_id
        """)

        methods = cursor.fetchall()

        return jsonify({
            "success": True,
            "payment_methods": methods
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# REGISTER
# ============================================================

@app.route("/api/register", methods=["POST"])
def register():

    db = None
    cursor = None

    try:

        data = request.get_json() or {}

        full_name = data.get("full_name")
        phone = data.get("phone")
        email = data.get("email")
        password = data.get("password")

        bank_id = data.get("bank_id")
        psp_id = data.get("psp_id")

        upi_id = data.get("upi_id")
        upi_pin = data.get("upi_pin")

        initial_balance = data.get("initial_balance", 500)

        if not full_name:
            return jsonify({
                "success": False,
                "message": "Full name is required"
            }), 400

        if not phone:
            return jsonify({
                "success": False,
                "message": "Phone number is required"
            }), 400

        if not password:
            return jsonify({
                "success": False,
                "message": "Password is required"
            }), 400

        if not bank_id:
            return jsonify({
                "success": False,
                "message": "Bank selection is required"
            }), 400

        if not psp_id:
            return jsonify({
                "success": False,
                "message": "PSP selection is required"
            }), 400

        if not upi_id:
            return jsonify({
                "success": False,
                "message": "UPI ID is required"
            }), 400

        if not upi_pin:
            return jsonify({
                "success": False,
                "message": "UPI PIN is required"
            }), 400

        if len(str(upi_pin)) != 6 or not str(upi_pin).isdigit():
            return jsonify({
                "success": False,
                "message": "UPI PIN must be exactly 6 digits"
            }), 400

        try:
            initial_balance = Decimal(str(initial_balance))

            if initial_balance < 0:
                raise ValueError

        except Exception:
            return jsonify({
                "success": False,
                "message": "Invalid initial balance"
            }), 400

        db = get_db()
        db.start_transaction()

        cursor = get_cursor(db)

        # CHECK PHONE

        cursor.execute("""
            SELECT user_id
            FROM users
            WHERE phone = %s
            LIMIT 1
        """, (phone,))

        if cursor.fetchone():

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Phone number already registered"
            }), 409

        # CHECK EMAIL

        if email:

            cursor.execute("""
                SELECT user_id
                FROM users
                WHERE email = %s
                LIMIT 1
            """, (email,))

            if cursor.fetchone():

                db.rollback()

                return jsonify({
                    "success": False,
                    "message": "Email already registered"
                }), 409

        # CHECK UPI ID

        cursor.execute("""
            SELECT upi_account_id
            FROM upi_accounts
            WHERE upi_id = %s
            LIMIT 1
        """, (upi_id,))

        if cursor.fetchone():

            db.rollback()

            return jsonify({
                "success": False,
                "message": "UPI ID already exists"
            }), 409

        # VERIFY BANK

        cursor.execute("""
            SELECT
                bank_id,
                bank_name,
                npci_id
            FROM banks
            WHERE bank_id = %s
            LIMIT 1
        """, (bank_id,))

        bank = cursor.fetchone()

        if not bank:

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Selected bank does not exist"
            }), 400

        # VERIFY PSP + NPCI

        cursor.execute("""
            SELECT
                p.psp_id,
                p.psp_name,
                p.npci_id,
                n.network_name
            FROM psps p
            JOIN npci n
                ON p.npci_id = n.npci_id
            WHERE p.psp_id = %s
            LIMIT 1
        """, (psp_id,))

        psp = cursor.fetchone()

        if not psp:

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Selected PSP does not exist"
            }), 400

        # CREATE USER

        password_hash = generate_password_hash(password)

        cursor.execute("""
            INSERT INTO users
            (
                full_name,
                phone,
                email,
                password
            )
            VALUES
            (
                %s,
                %s,
                %s,
                %s
            )
        """, (
            full_name,
            phone,
            email,
            password_hash
        ))

        user_id = cursor.lastrowid

        # ACCOUNT NUMBER

        while True:

            account_number = (
                str(phone) +
                uuid.uuid4().hex[:6]
            )[-20:]

            cursor.execute("""
                SELECT account_id
                FROM bank_accounts
                WHERE account_number = %s
                LIMIT 1
            """, (account_number,))

            if cursor.fetchone() is None:
                break

        # CREATE BANK ACCOUNT

        cursor.execute("""
            INSERT INTO bank_accounts
            (
                user_id,
                bank_id,
                account_number,
                balance,
                account_status
            )
            VALUES
            (
                %s,
                %s,
                %s,
                %s,
                %s
            )
        """, (
            user_id,
            bank_id,
            account_number,
            initial_balance,
            "ACTIVE"
        ))

        bank_account_id = cursor.lastrowid

        # CREATE UPI ACCOUNT

        cursor.execute("""
            INSERT INTO upi_accounts
            (
                user_id,
                bank_account_id,
                upi_id,
                upi_pin,
                status
            )
            VALUES
            (
                %s,
                %s,
                %s,
                %s,
                %s
            )
        """, (
            user_id,
            bank_account_id,
            upi_id,
            upi_pin,
            "ACTIVE"
        ))

        upi_account_id = cursor.lastrowid

        # PSP USER RELATIONSHIP

        cursor.execute("""
            INSERT INTO psp_users
            (
                psp_id,
                user_id
            )
            VALUES
            (
                %s,
                %s
            )
        """, (
            psp_id,
            user_id
        ))

        db.commit()

        return jsonify({
            "success": True,
            "message": "Registration successful",
            "user": {
                "user_id": user_id,
                "full_name": full_name,
                "phone": phone,
                "email": email,
                "upi_account_id": upi_account_id,
                "upi_id": upi_id,
                "bank_account_id": bank_account_id,
                "bank_name": bank["bank_name"],
                "psp_id": psp["psp_id"],
                "psp_name": psp["psp_name"],
                "npci_id": psp["npci_id"]
            }
        }), 201

    except Exception as e:

        if db:
            db.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# LOGIN
# ============================================================

@app.route("/api/login", methods=["POST"])
def login():

    db = None
    cursor = None

    try:

        data = request.get_json() or {}

        phone = data.get("phone")
        password = data.get("password")

        if not phone or not password:

            return jsonify({
                "success": False,
                "message": "Phone and password are required"
            }), 400

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                u.user_id,
                u.full_name,
                u.phone,
                u.email,
                u.password,

                ua.upi_account_id,
                ua.upi_id,
                ua.status AS upi_status,

                ba.account_id,
                ba.account_number,
                ba.balance,
                ba.account_status,

                b.bank_id,
                b.bank_name,
                b.bank_code,

                pu.psp_id,
                psp.psp_name,
                psp.npci_id,

                n.network_name

            FROM users u

            LEFT JOIN upi_accounts ua
                ON u.user_id = ua.user_id

            LEFT JOIN bank_accounts ba
                ON ua.bank_account_id = ba.account_id

            LEFT JOIN banks b
                ON ba.bank_id = b.bank_id

            LEFT JOIN psp_users pu
                ON u.user_id = pu.user_id

            LEFT JOIN psps psp
                ON pu.psp_id = psp.psp_id

            LEFT JOIN npci n
                ON psp.npci_id = n.npci_id

            WHERE u.phone = %s
            LIMIT 1
        """, (phone,))

        user = cursor.fetchone()

        if not user:

            return jsonify({
                "success": False,
                "message": "Invalid phone number or password"
            }), 401

        stored_password = str(user["password"])

        if stored_password.startswith(("pbkdf2:", "scrypt:")):

            try:
                password_valid = check_password_hash(
                    stored_password,
                    password
                )
            except Exception:
                password_valid = False

        else:

            password_valid = (
                stored_password == str(password)
            )

        if not password_valid:

            return jsonify({
                "success": False,
                "message": "Invalid phone number or password"
            }), 401

        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "user_id": user["user_id"],
                "full_name": user["full_name"],
                "phone": user["phone"],
                "email": user["email"],

                "upi_account_id": user["upi_account_id"],
                "upi_id": user["upi_id"],
                "upi_status": user["upi_status"],

                "account_id": user["account_id"],
                "account_number": user["account_number"],
                "balance": str(user["balance"]),
                "account_status": user["account_status"],

                "bank_id": user["bank_id"],
                "bank_name": user["bank_name"],
                "bank_code": user["bank_code"],

                "psp_id": user["psp_id"],
                "psp_name": user["psp_name"],
                "npci_id": user["npci_id"],
                "network_name": user["network_name"]
            }
        }), 200

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# GET USER PROFILE
# ============================================================

@app.route("/api/user/<int:user_id>", methods=["GET"])
def get_user(user_id):

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                u.user_id,
                u.full_name,
                u.phone,
                u.email,

                ua.upi_account_id,
                ua.upi_id,
                ua.status AS upi_status,

                ba.account_id,
                ba.account_number,
                ba.balance,
                ba.account_status,

                b.bank_id,
                b.bank_name,
                b.bank_code,

                pu.psp_id,
                psp.psp_name,
                psp.npci_id,

                n.network_name

            FROM users u

            LEFT JOIN upi_accounts ua
                ON u.user_id = ua.user_id

            LEFT JOIN bank_accounts ba
                ON ua.bank_account_id = ba.account_id

            LEFT JOIN banks b
                ON ba.bank_id = b.bank_id

            LEFT JOIN psp_users pu
                ON u.user_id = pu.user_id

            LEFT JOIN psps psp
                ON pu.psp_id = psp.psp_id

            LEFT JOIN npci n
                ON psp.npci_id = n.npci_id

            WHERE u.user_id = %s
            LIMIT 1
        """, (user_id,))

        user = cursor.fetchone()

        if not user:

            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        return jsonify({
            "success": True,
            "user": user
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# RESOLVE PAYEE
# ============================================================

@app.route("/api/resolve-payee", methods=["POST"])
def resolve_payee():

    db = None
    cursor = None

    try:

        data = request.get_json() or {}

        identifier = str(
            data.get("identifier", "")
        ).strip()

        if not identifier:

            return jsonify({
                "success": False,
                "message": "UPI ID or mobile number is required"
            }), 400

        db = get_db()
        cursor = get_cursor(db)

        payee = find_user_payment_account(
            cursor,
            identifier,
            lock=False
        )

        if not payee:

            return jsonify({
                "success": False,
                "message": "Payee not found"
            }), 404

        validate_payment_account(
            payee,
            "Payee"
        )

        return jsonify({
            "success": True,
            "payee": {
                "user_id": payee["user_id"],
                "full_name": payee["full_name"],
                "phone": payee["phone"],
                "upi_account_id": payee["upi_account_id"],
                "upi_id": payee["upi_id"],
                "bank_name": payee["bank_name"],
                "psp_name": payee["psp_name"],
                "network_name": payee["network_name"]
            }
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 400

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# PAYMENT
# ============================================================

@app.route("/api/pay", methods=["POST", "OPTIONS"])
def make_payment():

    if request.method == "OPTIONS":
        return "", 200

    db = None
    cursor = None

    try:

        data = request.get_json() or {}

        sender = str(data.get("sender", "")).strip()
        receiver = str(data.get("receiver", "")).strip()
        pin = str(data.get("pin", "")).strip()

        amount = data.get("amount")

        payment_method = data.get(
            "payment_method",
            "UPI ID"
        )

        remarks = data.get(
            "remarks",
            "UPI payment"
        )

        if not sender:
            return jsonify({
                "success": False,
                "message": "Sender is required"
            }), 400

        if not receiver:
            return jsonify({
                "success": False,
                "message": "Receiver is required"
            }), 400

        if amount is None:
            return jsonify({
                "success": False,
                "message": "Amount is required"
            }), 400

        if not pin:
            return jsonify({
                "success": False,
                "message": "UPI PIN is required"
            }), 400

        if len(pin) != 6 or not pin.isdigit():
            return jsonify({
                "success": False,
                "message": "UPI PIN must be exactly 6 digits"
            }), 400

        try:

            amount = Decimal(str(amount))

        except InvalidOperation:

            return jsonify({
                "success": False,
                "message": "Invalid amount"
            }), 400

        if amount <= 0:

            return jsonify({
                "success": False,
                "message": "Amount must be greater than 0"
            }), 400

        db = get_db()
        db.start_transaction()

        cursor = get_cursor(db)

        # PAYMENT METHOD

        payment_method_id = get_payment_method_id(
            cursor,
            payment_method
        )

        # GET SENDER

        sender_data = find_user_payment_account(
            cursor,
            sender,
            lock=False
        )

        validate_payment_account(
            sender_data,
            "Sender"
        )

        # CHECK PIN

        stored_pin = str(
            sender_data["upi_pin"]
        ).strip()

        if stored_pin != pin:

            failed_status_id = get_status_id(
                cursor,
                "FAILED"
            )

            transaction_id = generate_transaction_id(
                cursor
            )

            cursor.execute("""
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
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s
                )
            """, (
                transaction_id,
                sender_data["upi_account_id"],
                sender_data["upi_account_id"],
                amount,
                payment_method_id,
                failed_status_id,
                "Payment failed - incorrect UPI PIN"
            ))

            db.commit()

            return jsonify({
                "success": False,
                "message": "Incorrect UPI PIN",
                "transaction_id": transaction_id
            }), 400

        # GET RECEIVER

        receiver_data = find_user_payment_account(
            cursor,
            receiver,
            lock=False
        )

        validate_payment_account(
            receiver_data,
            "Receiver"
        )

        # SELF PAYMENT CHECK

        if (
            sender_data["upi_account_id"]
            == receiver_data["upi_account_id"]
        ):

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Sender and receiver cannot be the same"
            }), 400

        # LOCK ACCOUNTS

        account_ids = sorted([
            sender_data["account_id"],
            receiver_data["account_id"]
        ])

        locked_accounts = {}

        for account_id in account_ids:

            cursor.execute("""
                SELECT
                    account_id,
                    balance,
                    account_status
                FROM bank_accounts
                WHERE account_id = %s
                FOR UPDATE
            """, (account_id,))

            row = cursor.fetchone()

            if not row:
                raise ValueError(
                    "Bank account not found"
                )

            locked_accounts[
                row["account_id"]
            ] = row

        sender_account = locked_accounts[
            sender_data["account_id"]
        ]

        receiver_account = locked_accounts[
            receiver_data["account_id"]
        ]

        # ACCOUNT STATUS

        if sender_account["account_status"] != "ACTIVE":

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Sender bank account is inactive"
            }), 400

        if receiver_account["account_status"] != "ACTIVE":

            db.rollback()

            return jsonify({
                "success": False,
                "message": "Receiver bank account is inactive"
            }), 400

        # BALANCE

        if Decimal(
            str(sender_account["balance"])
        ) < amount:

            failed_status_id = get_status_id(
                cursor,
                "FAILED"
            )

            transaction_id = generate_transaction_id(
                cursor
            )

            cursor.execute("""
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
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s
                )
            """, (
                transaction_id,
                sender_data["upi_account_id"],
                receiver_data["upi_account_id"],
                amount,
                payment_method_id,
                failed_status_id,
                "Payment failed - insufficient balance"
            ))

            db.commit()

            return jsonify({
                "success": False,
                "message": "Insufficient balance",
                "transaction_id": transaction_id
            }), 400

        # DEDUCT PAYER

        cursor.execute("""
            UPDATE bank_accounts
            SET balance = balance - %s
            WHERE account_id = %s
        """, (
            amount,
            sender_data["account_id"]
        ))

        if cursor.rowcount != 1:
            raise Exception(
                "Unable to update payer balance"
            )

        # ADD PAYEE

        cursor.execute("""
            UPDATE bank_accounts
            SET balance = balance + %s
            WHERE account_id = %s
        """, (
            amount,
            receiver_data["account_id"]
        ))

        if cursor.rowcount != 1:
            raise Exception(
                "Unable to update payee balance"
            )

        # SUCCESS STATUS

        success_status_id = get_status_id(
            cursor,
            "SUCCESS"
        )

        # TRANSACTION ID

        transaction_id = generate_transaction_id(
            cursor
        )

        # INSERT TRANSACTION

        cursor.execute("""
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
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s
            )
        """, (
            transaction_id,
            sender_data["upi_account_id"],
            receiver_data["upi_account_id"],
            amount,
            payment_method_id,
            success_status_id,
            remarks
        ))

        # COMMIT

        db.commit()

        # UPDATED BALANCES

        cursor.execute("""
            SELECT balance
            FROM bank_accounts
            WHERE account_id = %s
        """, (
            sender_data["account_id"],
        ))

        sender_balance_row = cursor.fetchone()

        cursor.execute("""
            SELECT balance
            FROM bank_accounts
            WHERE account_id = %s
        """, (
            receiver_data["account_id"],
        ))

        receiver_balance_row = cursor.fetchone()

        new_sender_balance = sender_balance_row["balance"]
        new_receiver_balance = receiver_balance_row["balance"]

        return jsonify({
            "success": True,
            "message": "Payment successful",
            "transaction_id": transaction_id,
            "payment": {
                "payer": sender_data["full_name"],
                "payer_upi_id": sender_data["upi_id"],
                "payee": receiver_data["full_name"],
                "payee_upi_id": receiver_data["upi_id"],
                "amount": str(amount),
                "payment_method": payment_method,
                "status": "SUCCESS",
                "payer_balance": str(
                    new_sender_balance
                ),
                "payee_balance": str(
                    new_receiver_balance
                )
            }
        }), 200

    except Exception as e:

        if db:
            db.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# TRANSACTION HISTORY
# ============================================================

@app.route("/api/transactions/<int:user_id>", methods=["GET"])
def get_transactions(user_id):

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                t.transaction_id,
                t.amount,
                t.transaction_time,
                t.remarks,

                pm.method_name AS payment_method,

                ts.status_name,
                ts.description AS status_description,

                payer_user.user_id AS payer_user_id,
                payer_user.full_name AS payer_name,
                payer_upi.upi_id AS payer_upi_id,

                payee_user.user_id AS payee_user_id,
                payee_user.full_name AS payee_name,
                payee_upi.upi_id AS payee_upi_id

            FROM transactions t

            JOIN payment_methods pm
                ON t.payment_method_id =
                   pm.payment_method_id

            JOIN transaction_status ts
                ON t.status_id =
                   ts.status_id

            JOIN upi_accounts payer_upi
                ON t.payer_upi_id =
                   payer_upi.upi_account_id

            JOIN users payer_user
                ON payer_upi.user_id =
                   payer_user.user_id

            JOIN upi_accounts payee_upi
                ON t.payee_upi_id =
                   payee_upi.upi_account_id

            JOIN users payee_user
                ON payee_upi.user_id =
                   payee_user.user_id

            WHERE
                payer_user.user_id = %s
                OR payee_user.user_id = %s

            ORDER BY
                t.transaction_time DESC
        """, (
            user_id,
            user_id
        ))

        transactions = cursor.fetchall()

        return jsonify({
            "success": True,
            "transactions": transactions
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# ADD BENEFICIARY
# ============================================================

@app.route("/api/beneficiaries", methods=["POST"])
def add_beneficiary():

    db = None
    cursor = None

    try:

        data = request.get_json() or {}

        user_id = data.get("user_id")
        beneficiary_upi_id = data.get(
            "beneficiary_upi_id"
        )
        nickname = data.get("nickname")

        if not user_id or not beneficiary_upi_id:

            return jsonify({
                "success": False,
                "message":
                    "User ID and beneficiary UPI ID are required"
            }), 400

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT user_id
            FROM users
            WHERE user_id = %s
            LIMIT 1
        """, (user_id,))

        if not cursor.fetchone():

            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        cursor.execute("""
            SELECT
                ua.upi_account_id,
                ua.upi_id,
                u.full_name
            FROM upi_accounts ua
            JOIN users u
                ON ua.user_id = u.user_id
            WHERE ua.upi_id = %s
            LIMIT 1
        """, (beneficiary_upi_id,))

        beneficiary = cursor.fetchone()

        if not beneficiary:

            return jsonify({
                "success": False,
                "message": "Beneficiary UPI ID does not exist"
            }), 404

        cursor.execute("""
            SELECT beneficiary_id
            FROM beneficiaries
            WHERE user_id = %s
              AND beneficiary_upi_id = %s
            LIMIT 1
        """, (
            user_id,
            beneficiary_upi_id
        ))

        if cursor.fetchone():

            return jsonify({
                "success": False,
                "message": "Beneficiary already exists"
            }), 409

        cursor.execute("""
            INSERT INTO beneficiaries
            (
                user_id,
                beneficiary_upi_id,
                nickname
            )
            VALUES
            (
                %s,
                %s,
                %s
            )
        """, (
            user_id,
            beneficiary_upi_id,
            nickname
        ))

        db.commit()

        return jsonify({
            "success": True,
            "message": "Beneficiary added",
            "beneficiary_id": cursor.lastrowid
        }), 201

    except Exception as e:

        if db:
            db.rollback()

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# GET BENEFICIARIES
# ============================================================

@app.route(
    "/api/beneficiaries/<int:user_id>",
    methods=["GET"]
)
def get_beneficiaries(user_id):

    db = None
    cursor = None

    try:

        db = get_db()
        cursor = get_cursor(db)

        cursor.execute("""
            SELECT
                beneficiary_id,
                user_id,
                beneficiary_upi_id,
                nickname,
                added_at
            FROM beneficiaries
            WHERE user_id = %s
            ORDER BY added_at DESC
        """, (user_id,))

        beneficiaries = cursor.fetchall()

        return jsonify({
            "success": True,
            "beneficiaries": beneficiaries
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

    finally:

        if cursor:
            cursor.close()

        if db:
            db.close()


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )