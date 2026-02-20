from fastapi import FastAPI, Form, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from qdrant_client import QdrantClient
from qdrant_client.http import models
from langchain_qdrant import QdrantVectorStore
from langchain_huggingface import HuggingFaceEmbeddings
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
import os
import glob
import numpy as np
import re
from sentence_transformers import CrossEncoder, SentenceTransformer
from transformers import pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import traceback
import nltk
nltk.download('punkt')
nltk.download('stopwords')

# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# Initialize models
reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
semantic_model = SentenceTransformer('all-MiniLM-L6-v2')
query_rewriter = SentenceTransformer('paraphrase-MiniLM-L6-v2')

# Check if rank_bm25 is available
try:
    from rank_bm25 import BM25Okapi
    USE_BM25 = True
    print("Using BM25 for keyword search")
except ImportError:
    USE_BM25 = False
    print("rank_bm25 not found, using TF-IDF instead")

# Initialize embeddings and Qdrant
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
qdrant_client = QdrantClient("http://localhost:6333")
COLLECTION_NAME = "pdf_chunks"

# Ensure collection exists
def ensure_collection_exists():
    collections = [col.name for col in qdrant_client.get_collections().collections]
    if COLLECTION_NAME not in collections:
        qdrant_client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=models.VectorParams(size=768, distance=models.Distance.COSINE),
        )

ensure_collection_exists()

# Initialize qdrant_store
qdrant_store = QdrantVectorStore(
    client=qdrant_client,
    collection_name=COLLECTION_NAME,
    embedding=embeddings,
)

# Clean PDF text
def clean_text(text):
    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    # Remove special characters except basic punctuation
    text = re.sub(r'[^\w\s.,;:!?\-]', '', text)
    # Remove page numbers, headers, footers (customize based on your PDFs)
    text = re.sub(r'\d+\s*\n', '', text)  # Remove page numbers
    text = re.sub(r'[Hh]ttp[s]?://\S+', '', text)  # Remove URLs
    return text.strip()

# Load PDFs into Qdrant
def load_pdfs_to_qdrant():
    pdf_files = glob.glob("*.pdf")
    if not pdf_files:
        print("No PDF files found!")
        return

    all_chunks = []
    for pdf_file in pdf_files:
        print(f"\nProcessing {pdf_file}...")
        loader = PyPDFLoader(pdf_file)
        documents = loader.load()

        # Clean documents
        for doc in documents:
            doc.page_content = clean_text(doc.page_content)
            # Skip very short documents
            if len(doc.page_content.split()) < 20:
                continue

        # Split documents into chunks
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,       # Smaller chunks for better precision
            chunk_overlap=100,    # More overlap for context
            length_function=len,
            separators=["\n\n", "\n", " ", ""]  # Split by paragraphs first
        )
        chunks = text_splitter.split_documents(documents)

        for chunk in chunks:
            chunk.metadata["source"] = pdf_file
            print(f"Sample chunk: {chunk.page_content[:100]}...")  # Debug
        all_chunks.extend(chunks)

    if all_chunks:
        print(f"Adding {len(all_chunks)} chunks to Qdrant...")
        qdrant_store.add_documents(all_chunks)
        print(f"Successfully loaded {len(all_chunks)} chunks into Qdrant!")
    else:
        print("No valid chunks to load!")

# Load PDFs if collection is empty
collection_info = qdrant_client.get_collection(COLLECTION_NAME)
if collection_info.points_count == 0:
    load_pdfs_to_qdrant()
else:
    print(f"Collection has {collection_info.points_count} points.")

# Initialize keyword search
if USE_BM25:
    def init_keyword_search():
        docs = qdrant_store.client.scroll(
            collection_name=COLLECTION_NAME,
            limit=10000,
            with_payload=True,
        )[0]
        corpus = [doc.payload["page_content"] for doc in docs]
        tokenized_corpus = [doc.split(" ") for doc in corpus]
        return BM25Okapi(tokenized_corpus)

    keyword_search = init_keyword_search()
else:
    def init_tfidf_search():
        docs = qdrant_store.client.scroll(
            collection_name=COLLECTION_NAME,
            limit=10000,
            with_payload=True,
        )[0]
        corpus = [doc.payload["page_content"] for doc in docs]
        vectorizer = TfidfVectorizer()
        tfidf_matrix = vectorizer.fit_transform(corpus)
        return vectorizer, tfidf_matrix

    tfidf_vectorizer, tfidf_matrix = init_tfidf_search()

# Query expansion
def expand_query(question):
    """Generate alternative phrasings of the question"""
    # Simple expansion with different question formats
    return [
        question,
        f"What is {question}",
        f"Explain {question}",
        f"Define {question}",
        f"How does {question} work",
        f"Process of {question}",
        f"Information about {question}",
        f"Details on {question}"
    ]

# Query expansion with DistilGPT2
try:
    query_expander = pipeline('text-generation', model='distilgpt2')
except:
    query_expander = None

# Helper functions
def rerank_with_cross_encoder(question, documents_with_scores, top_k=10):
    """Re-rank documents using cross-encoder for better relevance"""
    doc_pairs = [(question, doc.page_content if hasattr(doc, 'page_content') else doc)
                for doc, _ in documents_with_scores]

    reranked_scores = reranker.predict(doc_pairs)
    combined_scores = [(doc, 0.7 * score + 0.3 * original_score)
                      for (doc, original_score), score
                      in zip(documents_with_scores, reranked_scores)]

    combined_scores.sort(key=lambda x: x[1], reverse=True)
    return combined_scores[:top_k]

def semantic_deduplication(documents_with_scores, threshold=0.85):
    """Remove semantically similar documents"""
    if not documents_with_scores:
        return []

    seen_embeddings = []
    unique_docs = []

    for doc, score in documents_with_scores:
        content = doc.page_content if hasattr(doc, 'page_content') else doc
        embedding = semantic_model.encode(content)

        # Check for duplicates
        is_duplicate = False
        for seen_emb in seen_embeddings:
            similarity = np.dot(embedding, seen_emb) / (
                np.linalg.norm(embedding) * np.linalg.norm(seen_emb)
            )
            if similarity > threshold:
                is_duplicate = True
                break

        if not is_duplicate:
            unique_docs.append((doc, score))
            seen_embeddings.append(embedding)

    return unique_docs

def filter_by_score(documents_with_scores, min_score=0.3):
    """Filter documents by minimum score"""
    if not documents_with_scores:
        return []

    return [(doc, score) for doc, score in documents_with_scores if score >= min_score]

# Debug endpoint to check stored documents
@app.get("/debug/docs")
async def debug_docs():
    try:
        docs = qdrant_store.client.scroll(
            collection_name=COLLECTION_NAME,
            limit=20,
            with_payload=True,
            with_vectors=False
        )[0]

        result = []
        for i, doc in enumerate(docs):
            result.append({
                "id": doc.id,
                "content": doc.payload["page_content"][:500] + "...",
                "source": doc.payload.get("source", "unknown"),
                "metadata": doc.payload.get("metadata", {})
            })

        return JSONResponse({"documents": result})
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)

# Main endpoint
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("chatbot.html", {"request": request})

@app.post("/ask/")
async def ask_question(question: str = Form(...)):
    try:
        print(f"\n\n=== New Question: {question} ===\n")

        # Step 1: Try expanded queries
        expanded_queries = expand_query(question)
        all_results = []

        for eq in expanded_queries:
            print(f"Trying expanded query: {eq}")
            results = qdrant_store.similarity_search_with_score(eq, k=10)
            all_results.extend(results)

        # Sort all results by score
        semantic_docs = sorted(all_results, key=lambda x: x[1], reverse=True)[:20]
        print(f"Found {len(semantic_docs)} semantic documents after query expansion")

        # Debug: Print top semantic results
        for i, (doc, score) in enumerate(semantic_docs[:3]):
            content = doc.page_content if hasattr(doc, 'page_content') else doc
            print(f"Top Semantic Doc {i+1} (Score: {score:.3f}): {content[:200]}...")

        if not semantic_docs:
            return JSONResponse({"answer": "No information found in semantic search."})

        # Step 2: Keyword search
        keyword_docs = []
        if USE_BM25:
            tokenized_question = question.lower().split()
            bm25_scores = keyword_search.get_scores(tokenized_question)
            top_bm25_indices = np.argsort(bm25_scores)[-10:][::-1]

            docs = qdrant_store.client.scroll(
                collection_name=COLLECTION_NAME,
                limit=10000,
                with_payload=True,
            )[0]
            for idx in top_bm25_indices:
                doc = docs[idx]
                keyword_docs.append((doc.payload["page_content"], bm25_scores[idx]))
        else:
            question_tfidf = tfidf_vectorizer.transform([question])
            cosine_similarities = cosine_similarity(question_tfidf, tfidf_matrix).flatten()
            top_tfidf_indices = np.argsort(cosine_similarities)[-10:][::-1]

            docs = qdrant_store.client.scroll(
                collection_name=COLLECTION_NAME,
                limit=10000,
                with_payload=True,
            )[0]
            for idx in top_tfidf_indices:
                doc = docs[idx]
                keyword_docs.append((doc.payload["page_content"], cosine_similarities[idx]))

        # Step 3: Combine and re-rank results
        combined_docs = semantic_docs + keyword_docs
        if combined_docs:
            reranked_docs = rerank_with_cross_encoder(question, combined_docs, top_k=15)

            # Debug: Print reranked results
            print("\n--- Top Reranked Results ---")
            for i, (doc, score) in enumerate(reranked_docs[:3]):
                content = doc.page_content if hasattr(doc, 'page_content') else doc
                print(f"Reranked Doc {i+1} (Score: {score:.3f}): {content[:200]}...")

            # Step 4: Deduplicate results
            unique_docs = semantic_deduplication(reranked_docs, threshold=0.85)

            # Step 5: Score-based filtering with lower threshold
            filtered_docs = filter_by_score(unique_docs, min_score=0.25)

            # Debug: Print filtered results
            print(f"\nFound {len(filtered_docs)} filtered documents:")
            for i, (doc, score) in enumerate(filtered_docs[:3]):
                content = doc.page_content if hasattr(doc, 'page_content') else doc
                print(f"Filtered Doc {i+1} (Score: {score:.3f}): {content[:200]}...")

            if not filtered_docs:
                # Try more permissive filtering
                permissive_docs = filter_by_score(reranked_docs, min_score=0.1)
                if permissive_docs:
                    permissive_docs.sort(key=lambda x: x[1], reverse=True)
                    top_docs = permissive_docs[:5]
                    answer_content = []
                    for doc, _ in top_docs:
                        content = doc.page_content if hasattr(doc, 'page_content') else doc
                        answer_content.append(content)
                    answer = "\n\n---\n\n".join(answer_content)
                    return JSONResponse({
                        "answer": answer,
                        "warning": "Some information was found but with low confidence. Here are the most relevant parts:"
                    })
                else:
                    return JSONResponse({"answer": "No relevant information found in the documents."})

            # Prepare final answer from filtered docs
            filtered_docs.sort(key=lambda x: x[1], reverse=True)
            top_docs = filtered_docs[:3]

            answer_content = []
            for doc, _ in top_docs:
                content = doc.page_content if hasattr(doc, 'page_content') else doc
                answer_content.append(content)

            answer = "\n\n---\n\n".join(answer_content)

            # If answer is empty, try to get at least something
            if not answer.strip():
                if reranked_docs:
                    top_docs = reranked_docs[:3]
                    answer_content = []
                    for doc, _ in top_docs:
                        content = doc.page_content if hasattr(doc, 'page_content') else doc
                        answer_content.append(content)
                    answer = "\n\n---\n\n".join(answer_content)
                    return JSONResponse({
                        "answer": answer,
                        "warning": "The answer might contain some less relevant information."
                    })

            return JSONResponse({"answer": answer})
        else:
            return JSONResponse({"answer": "No documents found after all processing steps."})

    except Exception as e:
        print(f"Error: {str(e)}")
        traceback.print_exc()
        return JSONResponse({"error": str(e)}, status_code=500)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
