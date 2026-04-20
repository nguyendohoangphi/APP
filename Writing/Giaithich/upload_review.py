import asyncio
import os
import sys
from pathlib import Path

# Add NotebookLM MCP path
M_PATH = r"c:/Users/Administrator/AndroidStudioProjects/Writing/notebooklm-mcp-main"
sys.path.append(M_PATH)

from src.notebooklm_mcp.api_client import NotebookLMClient
from src.notebooklm_mcp.auth import load_cached_tokens

async def main():
    print("🚀 Starting upload to NotebookLM...")
    
    # 1. Load Auth Tokens
    tokens = load_cached_tokens()
    if not tokens:
        print("❌ No auth tokens found! Please run 'notebooklm-mcp-auth' first.")
        return

    # 2. Initialize Client
    client = NotebookLMClient(
        cookies=tokens.cookies,
        csrf_token=tokens.csrf_token,
        session_id=tokens.session_id
    )
    
    # 3. Create Notebook
    notebook_title = "AI Engine System Review"
    print(f"Creating notebook: '{notebook_title}'...")
    try:
        # Use high-level method to ensure ID is parsed correctly
        notebook = client.create_notebook(title=notebook_title)
        if not notebook:
            print("❌ Failed to create notebook (returned None)")
            return
            
        notebook_id = notebook.id
        print(f"✅ Notebook created! ID: {notebook_id}")
    except Exception as e:
        print(f"❌ Failed to create notebook: {e}")
        return

    # 4. Upload Content
    file_path = r"C:\Users\Administrator\.gemini\antigravity\brain\20888c2b-bc91-4440-80e3-1271c820d865\ai_engine_review.md"
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        print(f"Uploading content from {file_path}...")
        
        # Use the proper method which handles the RPC structure correctly
        client.add_text_source(notebook_id, content, title="AI Engine Code Review")
        print("✅ Content uploaded successfully!")
        
        print("\n🎉 DONE! View your notebook here:")
        print(f"https://notebooklm.google.com/notebook/{notebook_id}")
        
    except Exception as e:
        print(f"❌ Failed to upload content: {e}")

if __name__ == "__main__":
    asyncio.run(main())
