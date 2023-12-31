import os
import json

from flask import Flask
app = Flask(__name__)

@app.route("/health")
def health():
    return '{"status": "ok"}'

@app.route("/")
def hello():
    return 'Hello world from ' + os.environ['HOSTNAME'] + ' ! v 2021-v2'

if __name__ == "__main__":
    app.run(host='0.0.0.0',port='80')

