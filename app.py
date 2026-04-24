"""
Simple web app for the Tunisia product availability agent.
Run: flask --app app run  (or python app.py)
"""

from dataclasses import asdict

from flask import Flask, jsonify, render_template, request

from agent import run_agent

app = Flask(__name__)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/search")
def search():
    q = (request.args.get("q") or "").strip()
    if not q:
        return jsonify({"error": "Missing query parameter 'q'"}), 400
    use_fallback = request.args.get("fallback", "true").lower() == "true"
    category = (request.args.get("category") or "auto").strip().lower()
    try:
        result = run_agent(q, use_search_fallback=use_fallback, category=category)
        return jsonify(asdict(result))
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, port=5000)
