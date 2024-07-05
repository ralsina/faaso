from flask import Flask

app = Flask({{name}})

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=5000)
