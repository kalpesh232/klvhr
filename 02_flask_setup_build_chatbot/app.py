from flask import Flask, jsonify, request
import requests

app = Flask(__name__)

OLLAMA_SERVER_URL = "http://192.168.22.81:11434/api/generate"

@app.route('/')
def hello():
    return "Hello World ..."

@app.route('/index', methods=['POST'])
def index():
    if request.method == 'POST':
        # Get the prompt from the POST request
        # prompt = request.json.get('prompt', 'Why is the sky blue?')
        data = request.get_json()

        print('prompt : ', data)

        prompt = data['key']

        # Send the prompt to the Ollama server
        response = requests.post(
            OLLAMA_SERVER_URL,
            json={
                "model": "llama2:latest",
                "prompt": prompt,
                "stream": False
            }
        )

        if response.status_code == 200:
            return jsonify({"response": response.json().get("response", "No response generated.")})
        else:
            return jsonify({"error": "Failed to get response from Ollama server."}), 500

    # Default GET response
    return "Send a POST request with a 'prompt' to get a response from the LLM."

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')