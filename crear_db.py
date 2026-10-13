import mysql.connector

conexion = mysql.connector.connect(
    host="192.168.1.10",
    user="root",
    password="1234"
)
cursor = conexion.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS hospital_sispa;")
print("¡Base de datos creada con éxito!")
conexion.close()