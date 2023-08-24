
import sqlite3
conn = sqlite3.connect('./moes_bar.db')
cursor = conn.cursor()

def list_tables():
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    return cursor.fetchall()

def show_schema(table):
    cursor.execute(f"pragma table_info({table})")
    return cursor.fetchall()

def name_of_youngest_customer():
    youngest_customer = ""
    cursor.execute(youngest_customer)
    return cursor.fetchall()

def drinks_from_most_to_least_expensive():
    cheapest_drinks = ""
    cursor.execute(cheapest_drinks)
    return cursor.fetchall()

def most_expensive_drink_bart_ordered():
    barts_orders = """ """
    cursor.execute(barts_orders)
    return cursor.fetchall()

def moes_customers():
    moe_customers = """ """
    cursor.execute(moe_customers)
    return cursor.fetchall()

def customers_by_profit():
    most_profitable_customer = """ """
    cursor.execute(most_profitable_customer)
    return cursor.fetchall()
