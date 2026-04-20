import asyncio
import os
import sys

# Add NotebookLM MCP path
M_PATH = r"c:/Users/Administrator/AndroidStudioProjects/Writing/notebooklm-mcp-main"
sys.path.append(M_PATH)

from src.notebooklm_mcp.api_client import NotebookLMClient
from src.notebooklm_mcp.auth import load_cached_tokens

# Configuration
FILES_TO_UPLOAD = [
    {
        "path": "coffee_app_review.md",
        "title": "Coffee App Mobile Source Review",
        "notebook_name": "Coffee App System Review" 
    },
    {
        "path": "ai_engine_review.md",
        "title": "AI Engine Detailed Review",
        "notebook_name": "Coffee App System Review"
    },
    {
        "path": "admin_web_review.md",
        "title": "Admin Web Detailed Review",
        "notebook_name": "Coffee App System Review"
    }
]

async def main():
    print("🚀 Starting Batch Upload to NotebookLM...")
    
    tokens = load_cached_tokens()
    if not tokens:
        print("❌ No auth tokens found!")
        return

    client = NotebookLMClient(
        cookies=tokens.cookies,
        csrf_token=tokens.csrf_token,
        session_id=tokens.session_id
    )
    
    # 1. Create OR Find Notebook (We'll just create a new one to be safe/clean)
    notebook_title = "Coffee App Full System Review"
    print(f"Creating centralized notebook: '{notebook_title}'...")
    try:
        notebook = client.create_notebook(title=notebook_title)
        if not notebook:
            print("❌ Creaetion failed.")
            return
        notebook_id = notebook.id
        print(f"✅ Notebook created! ID: {notebook_id}")
        print(f"🔗 Link: https://notebooklm.google.com/notebook/{notebook_id}\n")
    except Exception as e:
        print(f"❌ Error creating notebook: {e}")
        return

    # 2. Upload Files
    for item in FILES_TO_UPLOAD:
        file_path = os.path.join(os.path.dirname(__file__), item["path"])
        if not os.path.exists(file_path):
            print(f"⚠️ File not found: {item['path']}")
            continue
            
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            print(f"Uploading: {item['title']}...")
            client.add_text_source(notebook_id, content, title=item['title'])
            print("   ✅ Success")
        except Exception as e:
            print(f"   ❌ Failed: {e}")

    print("\n🎉 ALL DONE!")

if __name__ == "__main__":
    asyncio.run(main())
