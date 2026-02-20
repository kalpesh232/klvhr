import sys
print(sys.executable)  # Should show path to langchain_env\python.exe

from langchain_community.document_loaders import PyPDFLoader
print("Import successful!")