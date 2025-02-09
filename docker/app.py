from flask import Flask, jsonify
from prometheus_client import generate_latest, CollectorRegistry, CONTENT_TYPE_LATEST, ProcessCollector, PlatformCollector

app = Flask(__name__)

registry = CollectorRegistry()
ProcessCollector(registry=registry)
PlatformCollector(registry=registry)

@app.route('/')
def index():
    return jsonify(message="Hello, World from the container!")

@app.route('/health')
def health():
    return jsonify(status="OK"), 200

@app.route('/metrics')
def metrics():
    data = generate_latest(registry)
    return data, 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
