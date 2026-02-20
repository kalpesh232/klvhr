from flask import Flask , jsonify , request
import requests
from sentence_transformers import SentenceTransformer                   
import faiss                                       

app = Flask(__name__)
OLLAMA_SERVER_URL = "http://192.168.22.208:11434/api/generate"                        

documents = [
    "Oracle 19c patching requires OPatch version 12.2.0.1.23 or later.",
    "To apply a patch, use the command: opatch apply <patch_id>.",
    "Always back up your database before patching.",
    "Oracle patches are available on My Oracle Support (MOS)."
]

model  = SentenceTransformer('all-MiniLM-L6-v2') 
embeddings  = model.encode(documents)     # Text - 384 numbers                                          
dimension = embeddings.shape[1]           # 384                                     
index = faiss.IndexFlatL2(dimension)      # FAISS build index                                    
index.add(embeddings )                    # added embeddings into index                                     
print(f"FAISS index created with {index.ntotal} documents.")  

@app.route('/')
def hello():
    return "Hello World !"

@app.route('/ask', methods=["POST"])
def ask():
    if request.method == "POST" :
        data = request.get_json()      # receiving users question
        query  = data['key']           # Question 

        # step 1 : convert query into embedding
        query_embedding = model.encode([query])      
        # step 2 : search top 2 similer documents form FAISS
        distances, indies = index.search(query_embedding, k = 2)                 
        retrieved_docs = [documents[i] for i in indies[0]]
        print("Retrieved Documents:", retrieved_docs)                            

        # step 3 : make context with retrieved documents
        context = "\n".join(retrieved_docs)
        print("Context Sent to Ollama:", context)                 

        # step 4 : send prompt to ollama
        prompt  = f"""
            Answer the question using ONLY the following context. If the answer is not in the context, say "I don't know".
            Context:
            {context}
            Question: {query}
            Answer:
            """
        
        # step 5 : generate answer from Ollama
        response = requests.post( OLLAMA_SERVER_URL, json={ "model": "mistral:7b", "prompt": prompt, "temperature": 0.1, "stream" : False}).json()

        # step 6 : return the answer
        return jsonify({"answer": response['response']})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')