import requests 
from bs4 import BeautifulSoup
import re 
import time
from urllib.parse import urljoin, urlparse
import textwrap

urls = [
    "https://docs.oracle.com/en/database/oracle/oracle-database/18/ntqrf/overview-of-database-monitoring-tools.html",
    "https://docs.oracle.com/en-us/iaas/releasenotes/database-management/patch_management.htm",
    "https://docs.oracle.com/en/database/oracle/oracle-database/21/fppad/patching-oracle-database.html",
    "https://docs.oracle.com/en-us/iaas/database-management/doc/patching-oci-databases.html",
    "https://www.oracle.com/technical-resources/articles/it-infrastructure/patch-management-jsp.html",
    "https://docs.oracle.com/en-us/iaas/database-management/doc/vulnerability-detection-and-patching-concepts.html"

]

max_depth = 2
output_file = "oracle_knowledge.txt"
max_page_per_site = 15
KEYWORDS = ['oracle', 'database', 'db', 'monitor', 'monitoring', 'patch', 
                     'patching', 'management', 'performance', 'maintenance']

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
}

visited = set()
all_results = set()
pages_count = {}
patching = []
monitoring = []

def extract_oracle_sentences(text):
    patterns = [
        # Pattern 1: Oracle + monitoring/patches
        r'(oracle(\s+db|\s+database)?\s+(patch|patching|monitor|monitoring|patches)[^.]*\.)',
        # Pattern 2: Monitoring + database (even without "oracle")
        r'((database|db)\s+monitoring[^.]*\.)',
        # Pattern 3: Standalone monitoring/patches sentences that mention Oracle tools
        r'((Oracle|Enterprise Manager|OEM|Grid Control|Cloud Control|ASM|AWR|ADDM|ASH).*?(monitor|monitoring|patch|patching)[^.]*\.)',
        # Pattern 4: Monitoring tools/features
        r'((alert logs|performance monitoring|health monitoring|real-time monitoring)[^.]*\.)',
    ]

    sentences = []
    for pattern in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            sentences.append(match.group(0).strip())
     
    return sentences

def clean_and_format(text, width=90):
    text = re.sub(r'\s+',' ', text).strip()
    words = text.split()
    cleaned = []
    for w in words:
        if not cleaned or cleaned[-1].lower() != w.lower():
            cleaned.append(w)
    text = ' '.join(cleaned)
    return textwrap.fill(text, width=width)

def extract_relevant_content(soup):
    """Extract content from specific HTML elements that likely contain relevant info"""
    relevant_content = []
    
    # Look for content in specific elements
    elements = soup.find_all(['p', 'li', 'h2', 'h3', 'h4', 'div', 'section'])
    
    for element in elements:
        # Skip navigation, headers, footers
        if element.find_parent(['nav', 'header', 'footer', 'aside']):
            continue
            
        text = element.get_text(separator=" ", strip=True)
        if len(text) > 20:  # Only consider substantial content
            # Check if text contains any of our keywords
            if any(keyword in text.lower() for keyword in KEYWORDS):
                # Also look for monitoring-related terms
                monitoring_terms = ['monitor', 'monitoring', 'performance', 'alert', 'health', 
                                  'metric', 'threshold', 'notification', 'dashboard', 'track']
                patching_terms = ['patch', 'patching', 'update', 'upgrade', 'security', 
                                'vulnerability', 'fix', 'maintenance']
                
                if (any(term in text.lower() for term in monitoring_terms) or 
                    any(term in text.lower() for term in patching_terms)):
                    relevant_content.append(text)
    
    return relevant_content


def crawl(url, base_domain, depth=0):

    if depth > max_depth :
        return
    if pages_count.get(base_domain, 0) >= max_page_per_site :
        return
    if url in visited:
        return
    
    visited.add(url)
    pages_count[base_domain] = pages_count.get(base_domain, 0) + 1
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return
    
    soup = BeautifulSoup(response.text, "html.parser")
    text = soup.get_text(separator=" ", strip=True)
    relevant_content = extract_relevant_content(soup)

    all_text = text + " " + " ".join(relevant_content)

    found = extract_oracle_sentences(all_text)
    for sentence in found :
        all_results.add(sentence)

    if not found :
        return 
    
    for content in relevant_content:
        sentences = re.split(r'(?<=[.!?])\s+', content)
        for sentence in sentences:
            sentence_lower = sentence.lower()
            if ('monitor' in sentence_lower or 'monitoring' in sentence_lower or 
                'patch' in sentence_lower or 'patching' in sentence_lower):
                all_results.add(sentence.strip())
    
    for a in soup.find_all("a", href=True):
        next_url = urljoin(url, a["href"])
        parsed = urlparse(next_url)

        if parsed.netloc != base_domain :
            continue

        link_text = (a.get_text() + next_url).lower()

        if any(term in link_text for term in KEYWORDS):
            time.sleep(0.5)
            crawl(next_url, base_domain, depth + 1)


if __name__ == '__main__':
    for url in urls:
        domain = urlparse(url).netloc
        print(f"Crawling: {url}")
        crawl(url, domain)

    for line in all_results:
        l = line.lower()
        if "patch" in l or "patching" in l:
            patching.append(clean_and_format(line))
        elif "monitor" in l or "monitoring" in l:
            monitoring.append(clean_and_format(line))
        elif ("monitor" in l or "monitoring" in l) and ("patch" in l or "patching" in l):
            monitoring.append(clean_and_format(line))
            patching.append(clean_and_format(line))

    def remove_duplicates_ordered(lst):
        seen = set()
        result = []
        for item in lst:
            # Use a normalized version for comparison
            norm = re.sub(r'\s+', ' ', item.lower()).strip()
            if norm not in seen:
                seen.add(norm)
                result.append(item)
        return result
    
    patching = remove_duplicates_ordered(patching)
    monitoring = remove_duplicates_ordered(monitoring)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("ORACLE DATABASE PATCHING\n")
        f.write("=" * 30 + "\n\n")
        
        for i, p in enumerate(patching, 1):
            f.write(f"{i}. {p}\n\n")
        
        f.write("\n\nORACLE DATABASE MONITORING\n")
        f.write("=" * 32 + "\n\n")
        
        if monitoring:
            for i, m in enumerate(monitoring, 1):
                f.write(f"{i}. {m}\n\n")
        else:
            f.write("No monitoring-specific content found. Try these suggestions:\n")
            f.write("1. Add more monitoring-specific URLs to your list\n")
            f.write("2. Increase max_depth to crawl more pages\n")
            f.write("3. Add more monitoring-related keywords\n")
    
    print("\nCrawling finished successfully!")
    print(f"Pages visited: {len(visited)}")
    print(f"Oracle sentences collected: {len(all_results)}")
    print(f"Patching sentences: {len(patching)}")
    print(f"Monitoring sentences: {len(monitoring)}")
    print(f"Output saved to: {output_file}")