
import json
import time
import os
import sys
from pathlib import Path

# Add NotebookLM MCP path if needed
M_PATH = r"c:/Users/Administrator/AndroidStudioProjects/Writing/notebooklm-mcp-main"
sys.path.append(os.path.join(M_PATH, "src"))

try:
    from notebooklm_mcp.auth import AuthTokens, save_tokens_to_cache, get_cache_path
except ImportError:
    print("❌ Không tìm thấy thư viện notebooklm_mcp. Vui lòng kiểm tra lại đường dẫn.")
    sys.exit(1)

def manual_import():
    print("=== NotebookLM MCP - Nhập Cookie Thủ Công ===")
    print("\nBước 1: Mở trình duyệt và truy cập https://notebooklm.google.com")
    print("Bước 2: F12 -> tab Network -> tìm 'batchexecute'")
    print("Bước 3: Click 1 request, copy toàn bộ giá trị trong Header 'cookie'")
    print("\n" + "-"*50)
    
    cookie_string = input("\nDán Cookie của bạn vào đây và nhấn Enter:\n> ").strip()
    
    if not cookie_string:
        print("❌ Bạn chưa nhập gì cả!")
        return

    # Parse cookies
    cookies = {}
    for cookie in cookie_string.split(";"):
        cookie = cookie.strip()
        if "=" in cookie:
            key, value = cookie.split("=", 1)
            cookies[key.strip()] = value.strip()

    if not cookies:
        print("❌ Không thể phân tích cookie. Hãy đảm bảo bạn copy đúng định dạng 'key=value; ...'")
        return

    # Create tokens object
    tokens = AuthTokens(
        cookies=cookies,
        csrf_token="",  # Sẽ tự động lấy sau
        session_id="",  # Sẽ tự động lấy sau
        extracted_at=time.time(),
    )

    # Save to cache
    save_tokens_to_cache(tokens)
    print(f"\n✅ THÀNH CÔNG! Đã lưu cookie vào: {get_cache_path()}")
    print("Bây giờ bạn có thể chạy lại file upload_review.py")

if __name__ == "__main__":
    manual_import()
