from flask import Flask, jsonify, request, render_template
from PyPDF2 import PdfReader
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, PointStruct
import re
import uuid
import requests

app = Flask(__name__)

def extract_text_from_pdf(pdf_path):
    pages_data = []
    reader = PdfReader(pdf_path)                                                    # opens , extract 
    # for loop that iterates over the pages of a PDF file using the PyPDF2 library.
    for page_no, page in enumerate(reader.pages, start=1):
        # takes all the text from a PDF page and gives it to you as plain text.
        text = page.extract_text()                                        
        pages_data.append((page_no, text))
    return pages_data

def split_text_into_chunks(text, chunk_size=100):
    # This line splits text into sentences wherever ., !, or ? is followed by whitespace.
    sentences = re.split(r'(?<=[.!?])\s+', text) 
    chunks, current = [], ""
    for s in sentences :
        if len((current + s).split()) <= chunk_size:
            current += " " + s
        else:
            chunks.append(current.strip())
            current = s
    
    if current :
        chunks.append(current.strip())
    return chunks    

PDF_PATH = "HDFC Life_Study Materials.pdf"
pages = extract_text_from_pdf(PDF_PATH)

documents = []
for page_no, text in pages:
    chunks = split_text_into_chunks(text)
    for chunk in chunks:
        documents.append({
            "text": chunk,
            "page": page_no
        })

model = SentenceTransformer("all-MiniLM-L6-v2")
embeddings = model.encode([d["text"] for d in documents])

COLLECTION_NAME = 'pdf_chunks'


# ---------- QDRANT ----------
client = QdrantClient(url="http://localhost:6333")
# delete an existing collection (if it exists) and create a new, empty one
client.recreate_collection(
    collection_name=COLLECTION_NAME,
    vectors_config=VectorParams(size=embeddings.shape[1], distance=Distance.COSINE),
)

# It prepares your PDF text chunks so they can be stored in the Qdrant database.
points = []
for i , doc in enumerate(documents):
    points.append(
        PointStruct(
            id = str(uuid.uuid4()),
            vector = embeddings[i].tolist(),
            payload = {
                "text" : doc["text"],
                "page" : doc["page"]
            }
        )
    )

#  uploads all your PDF chunks (text, embeddings, and page numbers) into the Qdrant database.
client.upsert(collection_name=COLLECTION_NAME, points = points)# combination of "update" and "insert".
OLLAMA_SERVER_URL = "http://localhost:11434/api/generate"

@app.route('/')
def home():
    return "Hello World !!"

@app.route('/ask', methods=["POST", "GET"])
def ask():
    if request.method == "POST" :
        # query = request.json['Bot']
        data = request.get_json()
        print("data ____________________________", data)
        query = data.get('question', '')
        query_vector = model.encode(query).tolist()                                          # len 384
        results = client.search(
            collection_name = COLLECTION_NAME,
            query_vector = query_vector,           
            limit = 3
        )

        top_chunks = []
        for r in results:
            top_chunks.append({
                "text" : r.payload["text"],
                "page" : r.payload["page"]
            })

        context = " ".join([c["text"] for c in top_chunks])

        if not context.strip():
            answer = "Data Not found"
        else:
            prompt = f"""
            Answer the question using ONLY the context.
            If the context is not relevant, say "Data not found in PDF."

            Context:
            {context}

            Question: {query}
            Answer:
            """

            response = requests.post(
                OLLAMA_SERVER_URL,
                json={
                    "model": "gemma3:1b",
                    "prompt": prompt,
                    "temperature": 0.1,
                    "stream": False
                }
            ).json()
        
            answer = response['response']
                                        
        return jsonify({
            "question" : query,
            "top_context" : top_chunks,
            "answer" : answer
        })
    else:
        return render_template("chatbot.html")


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')