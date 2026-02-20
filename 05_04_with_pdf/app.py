from flask import Flask, jsonify, request
from PyPDF2 import PdfReader
from sentence_transformers import SentenceTransformer
import faiss
import re
import requests

app = Flask(__name__)
OLLAMA_SERVER_URL = "http://localhost:11434/api/generate" 

def extract_text_from_pdf(pdf_path):
    text = ""
    with open(pdf_path, "rb") as file :                       # PDF files binary format mein hote hain
        reader = PdfReader(file)                              # PDF file ko open karta hai.
        for page in reader.pages :
            text += page.extract_text()                       # Page se text nikalo.
    return text

# Bade documents (PDFs) ko FAISS/Ollama ke liye manageable pieces mein todne ke liye.
def split_text_into_chunks(text, chunk_size=100, overlap=30):
    sentences = re.split(r'(?<=[.!?])\s+', text)
    chunks = []
    current_chunk = ""
    for sentence in sentences :
        if len(current_chunk.split()) + len(sentence.split()) <= chunk_size :
            current_chunk += " " + sentence
        else:
            chunks.append(current_chunk.strip())
            current_chunk = sentence
    if current_chunk :
        chunks.append(current_chunk.strip())
    return chunks

PDF_PATH = "HDFC Life_Study Materials.pdf"
pdf_text = extract_text_from_pdf(PDF_PATH)
documents = split_text_into_chunks(pdf_text)
number_of_documents = documents
print(f"Number of documents (chunks): {number_of_documents}")

# RAG setup
model = SentenceTransformer('all-MiniLM-L6-v2')                                         # Text numbers
embeddings = model.encode(documents)      # Har document ko 384 numbers (embedding) mein convert karo.
# Each embedding has 384 numbers. Store this number in dimension.
dimension = embeddings.shape[1]
# FAISS database RAM (memory) mein banane ke liye, taaki similar embeddings (documents) ko fast search kar sakein.
index = faiss.IndexFlatL2(dimension)                  # L2 distance se similar embeddings dhoondta hai
# Sab embeddings ko FAISS database mein daal do, taaki baad mein search kar sakein.
index.add(embeddings)
print(f"FAISS index created with {index.ntotal} chunks from PDF.")
# 2. Index ko disk par save kare
# faiss.write_index(index, "faiss_index.bin")  # Save to disk

@app.route('/', methods = ["GET"])
def home():
    return "Building PDF RAG Chatbot !"

@app.route('/ask', methods=["POST"])
def ask():
    if request.method == "POST":
        data = request.get_json()
        query = data['key']

        query_embedding = model.encode([query])
        distances, indices = index.search(query_embedding, k=3)
        retrieved_docs = [documents[i] for i in indices[0]]

        if not retrieved_docs :
            return jsonify({"answer": "Data not found in the provided PDF."})
        
        context = "\n".join(retrieved_docs)

        prompt = f"""
        Answer the question using ONLY the EXACT sentence from the context.
        If the exact sentence is not found, say "Data not found in the PDF."

        Context:
        {" ".join(retrieved_docs)}

        Question: {query}
        Answer:
        """

        # Give me one clear, straight, full answer at once
        response = requests.post(OLLAMA_SERVER_URL,
                                 json={"model":"gemma3:1b", "prompt":prompt, "temperature":0.1, "stream":False}).json()
        
        return jsonify({"answer": response['response']})

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0')