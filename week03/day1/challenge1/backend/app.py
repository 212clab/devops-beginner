# app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return "Welcome to my ADDED backend!"

@app.route("/api/health")
def health_check():
    # 실제로는 여기서 데이터베이스 연결 등을 확인합니다.
    return jsonify(status="ok", message="Backend is healthy!")

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)