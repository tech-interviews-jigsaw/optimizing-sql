
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
    youngest_customer = "select name, min(birthyear) from customers;"
    cursor.execute(youngest_customer)
    return cursor.fetchall()

def drinks_from_most_to_least_expensive():
    cheapest_drinks = "select name, price from drinks ORDER BY price DESC;"
    cursor.execute(cheapest_drinks)
    return cursor.fetchall()

def most_expensive_drink_bart_ordered():
    barts_orders = """select drinks.name, max(drinks.price) from drinks
    join orders on orders.drink_id = drinks.id
    join customers on customers.id = orders.customer_id
    where customers.name = 'bart simpson';"""
    cursor.execute(barts_orders)
    return cursor.fetchall()

def moes_customers():
    moe_customers = """select DISTINCT(customers.name) from customers
    join orders on orders.customer_id = customers.id
    join bartenders on bartenders.id = orders.bartender_id
    where bartenders.name = 'moe';"""
    cursor.execute(moe_customers)
    return cursor.fetchall()

def customers_by_profit():
    most_profitable_customer = """select customers.name, SUM(drinks.price) - SUM(ingredients.price) as profit FROM ingredients
    INNER JOIN ingredients_drinks ON ingredients_drinks.ingredient_id = ingredients.id
    INNER JOIN drinks ON drinks.id = ingredients_drinks.drink_id
    INNER JOIN customers ON orders.customer_id = customers.id
    INNER JOIN orders ON orders.drink_id = drinks.id GROUP BY orders.customer_id ORDER BY profit DESC;"""
    cursor.execute(most_profitable_customer)
    return cursor.fetchall()
