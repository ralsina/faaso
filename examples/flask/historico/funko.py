import json
import unicodedata

import psycopg2
from flask import Flask, request

app = Flask("historico")

USER = open("/secrets/user").read().strip()
PASS = open("/secrets/pass").read().strip()
conn = psycopg2.connect(dbname="nombres", user=USER, password=PASS, host="database")


@app.route("/", methods=["GET"])
def handle():
    names = [n.strip() for n in request.args.get("names").split(",")][:4]
    cursor = conn.cursor()
    # Prepare results table
    results = [["Año"] + names]
    results += [[year] + [0 for _ in names] for year in range(1922, 2016)]
    for i, name in enumerate(names):
        nfkd_form = unicodedata.normalize("NFKD", name)
        name = "".join([c for c in nfkd_form if not unicodedata.combining(c)])
        cursor.execute(
            "SELECT anio, contador FROM nombres WHERE nombre = %s",
            (name,),
        )
        for anio, contador in cursor.fetchall():
            results[anio - 1921][i + 1] = contador
    cursor.close()
    return json.dumps(results)


@app.route("/ping")
def ping():
    cursor = conn.cursor()
    cursor.execute("SELECT 42")
    cursor.fetchall()
    cursor.close()
    return "OK"
