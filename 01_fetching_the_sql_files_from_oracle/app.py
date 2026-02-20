import requests
from bs4 import BeautifulSoup
import os


url = "https://oracle-base.com/dba"
SUB_DIR = "monitoring/"

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Referer": url,
    "Connection": "keep-alive",
}


response = requests.get(url, headers=headers)
response.raise_for_status()  

soup = BeautifulSoup(response.text, "html.parser")

sql_links = [a['href'] for a in soup.find_all('a', href=True) if a['href'].endswith('.sql')]


os.makedirs("sql_files1", exist_ok=True)


with open("all_sql_files_combined1.sql", "w", encoding="utf-8") as combined_file:
    for link in sql_links:
        link = link.replace("\\", "/")
        if not link.startswith("http"):
            file_url = f"{url.rstrip('/')}/{link.lstrip('/')}"
        else:
            file_url = link
        
        
        print("*"*50, file_url)
        file_resp = requests.get(file_url, headers=headers, timeout=30)
        print(file_resp.status_code)
        file_resp.raise_for_status()
        content = file_resp.text

        
        file_name = os.path.join("sql_files", os.path.basename(link))
        with open(file_name, "w", encoding="utf-8") as f:
            f.write(content)

        
        combined_file.write(f"\n-- ########## Start of {os.path.basename(link)} ##########--\n")
        combined_file.write(content)
        combined_file.write(f"\n-- End of {os.path.basename(link)} --\n")

print("All SQL files fetched and saved successfully.")
