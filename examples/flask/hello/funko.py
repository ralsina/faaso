from flask import Flask, request

app = Flask("hello")

@app.route('/')
def handle():
    return "Hello World from Flask!"

@app.route('/ping')
def ping():
    return "OK"
