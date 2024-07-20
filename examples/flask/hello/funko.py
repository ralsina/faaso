from flask import Flask

app = Flask("hello")

@app.route('/')
def handle(req):
    return "Hello World from Flask!"

@app.route('/ping')
def handle(req):
    return "OK"
