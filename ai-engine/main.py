from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline
import pandas as pd
import uvicorn
import random
import os
import ast
import json
import re

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load all data on startup."""
    load_phobert_model()
    load_menu_data()
    yield

app = FastAPI(title="Coffee Shop AI Chatbot - Generic Labels", lifespan=lifespan)

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str
    intent: Optional[str] = None
    confidence: Optional[float] = None
    extracted_entity: Optional[str] = None

PHOBERT_MODEL_PATH = "phobert_final_clean"
DATASET_PATH = "dataset.xlsx"
DATA_JS_PATH = "../admin-web/public/data.js"

GENERIC_LABELS = [
    "GREETING", "THANKS", "OTHER",
    "GET_MENU", "GET_CATEGORY", "ASK_PRICE",
    "SUGGEST_COLD", "SUGGEST_HOT", "SUGGEST_SWEET", "SUGGEST_LESS_SUGAR",
    "SUGGEST_HEALTHY", "SUGGEST_ENERGY", "SUGGEST_RELAX",
    "SUGGEST_COFFEE", "SUGGEST_TEA", "SUGGEST_FRUIT", "SUGGEST_CHOCOLATE",
    "SUGGEST_CARAMEL", "SUGGEST_MATCHA", "SUGGEST_FREEZE", "SUGGEST_CREAM",
    "SUGGEST_SNACK", "SUGGEST_CAKE", "SUGGEST_SPICY", "SUGGEST_SALTY",
    "SUGGEST_CRISPY", "SUGGEST_REFRESHING", "SUGGEST_VITAMIN", 
    "SUGGEST_VEGETABLE", "SUGGEST_DETOX"
]

phobert_classifier = None
MENU_DATA = {}
ALL_PRODUCTS = {}
CATEGORY_KEYWORDS = {}

def load_phobert_model():
    """Load PhoBERT fine-tuned classifier (12 generic labels)."""
    global phobert_classifier, GENERIC_LABELS
    if os.path.exists(PHOBERT_MODEL_PATH):
        try:
            phobert_classifier = pipeline(
                "text-classification",
                model=PHOBERT_MODEL_PATH,
                tokenizer=PHOBERT_MODEL_PATH,
                device=-1
            )
            print(f"✅ Loaded PhoBERT classifier from {PHOBERT_MODEL_PATH}")
            
            label_mapping_path = os.path.join(PHOBERT_MODEL_PATH, "label_mapping.json")
            if os.path.exists(label_mapping_path):
                with open(label_mapping_path, 'r', encoding='utf-8') as f:
                    label_data = json.load(f)
                    GENERIC_LABELS = label_data.get("labels", GENERIC_LABELS)
                    print(f"✅ Loaded {len(GENERIC_LABELS)} labels")
            return True
        except Exception as e:
            print(f"❌ Error loading PhoBERT: {e}")
    else:
        print(f"⚠️ PhoBERT model not found at {PHOBERT_MODEL_PATH}")
    return False

def load_menu_data():
    """Load menu from data.js and build keyword mapping."""
    global MENU_DATA, ALL_PRODUCTS, CATEGORY_KEYWORDS
    try:
        with open(DATA_JS_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
        start, end = content.find('['), content.rfind(']') + 1
        data = ast.literal_eval(content[start:end])
        
        for cat in data:
            cat_key = cat['name'].lower()
            display_name = cat.get('displayName', cat['name'])
            
            MENU_DATA[cat_key] = {
                'displayName': display_name,
                'products': cat.get('products', [])
            }
            
            keywords = generate_category_keywords(cat_key, display_name)
            for kw in keywords:
                CATEGORY_KEYWORDS[kw] = cat_key
            
            for prod in cat.get('products', []):
                ALL_PRODUCTS[prod['name'].lower()] = {
                    'name': prod['name'],
                    'price': prod['price'],
                    'description': prod.get('description', ''),
                    'category': display_name,
                    'tags': prod.get('tags', [])
                }
        
        print(f"✅ Loaded {len(MENU_DATA)} categories, {len(ALL_PRODUCTS)} products")
        print(f"✅ Generated {len(CATEGORY_KEYWORDS)} category keywords for extraction")
    except Exception as e:
        print(f"⚠️ Error loading menu: {e}")

def generate_category_keywords(cat_key: str, display_name: str) -> list:
    """Generate multiple keyword variations for a category."""
    keywords = [cat_key, display_name.lower()]
    
    aliases = {
        'freeze': ['đá xay', 'da xay', 'frappe', 'blended', 'xay'],
        'cocoa': ['sô cô la', 'so co la', 'chocolate', 'cacao', 'socola'],
        'tea': ['trà', 'tra', 'tea'],
        'cake': ['bánh', 'banh', 'bánh ngọt', 'banh ngot', 'dessert', 'tráng miệng'],
        'coffee': ['cà phê', 'ca phe', 'cafe', 'coffee', 'cf'],
        'snack': ['ăn vặt', 'an vat', 'snack', 'đồ ăn vặt'],
        'juice': ['nước ép', 'nuoc ep', 'juice', 'sinh tố', 'sinh to']
    }
    
    if cat_key in aliases:
        keywords.extend(aliases[cat_key])
    
    return list(set(keywords))

def extract_category_entity(message: str) -> tuple:
    """
    Extract category name from message.
    Returns: (category_key, matched_keyword) or (None, None)
    
    This is the KEY function that allows model to NOT depend on category names.
    Model only knows "GET_CATEGORY", this function extracts WHICH category.
    """
    msg = message.lower()
    
    sorted_keywords = sorted(CATEGORY_KEYWORDS.keys(), key=len, reverse=True)
    
    for keyword in sorted_keywords:
        if keyword in msg:
            return CATEGORY_KEYWORDS[keyword], keyword
    
    return None, None



#Dictionary-based Matching.
def extract_product_entity(message: str) -> dict:
    """
    Extract product name from message.
    Returns product info or None.
    
    Model only knows "ASK_PRICE", this function extracts WHICH product.
    """
    msg = message.lower()
    
    sorted_products = sorted(ALL_PRODUCTS.keys(), key=len, reverse=True)
    
    for name in sorted_products:
        if name in msg:
            return ALL_PRODUCTS[name]
    
    return None




def classify_with_phobert(message: str) -> tuple:
    """
    Classify message using PhoBERT.
    Model outputs GENERIC labels, not specific category/product names.
    """
    if not phobert_classifier:
        return "OTHER", 0.0
    try:
        result = phobert_classifier(message)[0]
        label_id = int(result['label'].replace('LABEL_', ''))
        if label_id < len(GENERIC_LABELS):
            intent = GENERIC_LABELS[label_id]
            confidence = result['score']
            print(f"🤖 PhoBERT: '{message[:50]}...' → {intent} ({confidence:.2%})")
            return intent, confidence
    except Exception as e:
        print(f"❌ PhoBERT error: {e}")
    return "OTHER", 0.0

def format_price(price: int) -> str:
    return f"{price:,}đ".replace(",", ".")

def filter_products_by_tag(target_tag: str) -> list:
    """Helper to filter products by a specific tag."""
    matched = []
    for prod in ALL_PRODUCTS.values():
        if target_tag in prod.get('tags', []):
            matched.append(prod['name'])
    return matched

def handle_greeting() -> str:
    responses = [
        "Xin chào! Mình là trợ lý AI của quán. Bạn muốn uống gì? ☕",
        "Chào bạn! Hôm nay bạn muốn thưởng thức gì nào? 😊",
        "Hello! Mình có thể giúp gì cho bạn? ☕"
    ]
    return random.choice(responses)

def handle_thanks() -> str:
    responses = [
        "Không có chi! Chúc bạn ngon miệng! 😊",
        "Cảm ơn bạn đã ghé quán! 🙏",
        "Rất vui được phục vụ bạn! 😄"
    ]
    return random.choice(responses)

def handle_get_menu() -> str:
    """Return all categories from database."""
    if not MENU_DATA:
        return "Xin lỗi, menu đang được cập nhật."
    
    cats = [f"• {c['displayName']}" for c in MENU_DATA.values()]
    return f"📋 Menu của quán:\n" + "\n".join(cats) + "\n\nBạn muốn xem gì?"

def handle_get_category(message: str) -> tuple:
    """
    Handle category query with entity extraction.
    Model knows "GET_CATEGORY", this function finds WHICH category.
    """
    cat_key, matched = extract_category_entity(message)
    
    if cat_key and cat_key in MENU_DATA:
        cat_data = MENU_DATA[cat_key]
        prods = ", ".join([f"{p['name']} ({format_price(p['price'])})" 
                          for p in cat_data['products'][:6]])
        response = f"📂 {cat_data['displayName']} có:\n{prods}"
        return response, matched
    
    cats = ", ".join([c['displayName'] for c in MENU_DATA.values()])
    return f"Quán có các danh mục: {cats}. Bạn muốn xem loại nào?", None

def handle_ask_price(message: str) -> tuple:
    """
    Handle price query with entity extraction.
    Model knows "ASK_PRICE", this function finds WHICH product.
    """
    product = extract_product_entity(message)
    
    if product:
        response = f"🏷️ {product['name']}: {format_price(product['price'])}"
        if product['description']:
            response += f"\n📝 {product['description']}"
        return response, product['name']
    
    return "Bạn muốn hỏi giá món nào? Cho mình biết tên món nhé! 😊", None

def handle_other(message: str = "") -> str:
    """
    Fallback handler.
    IMPROVEMENT: If intent is unclear but message contains a product name -> Treat as ASK_PRICE.
    Example: User says "Cappuccino" (intent OTHER) -> Returns price/desc of Cappuccino.
    """
    if message:
        product = extract_product_entity(message)
        if product:
            response = f"🏷️ {product['name']}: {format_price(product['price'])}"
            if product['description']:
                response += f"\n📝 {product['description']}"
            return response

    return "Mình chưa hiểu lắm. Thử hỏi: 'Menu có gì?', 'Cà phê có gì?', hoặc 'Gợi ý món lạnh đi' 😊"

def handle_suggestion(intent: str) -> str:
    """
    Dynamic handler for all SUGGEST_* intents.
    Maps INTENT -> TAG (e.g., SUGGEST_COLD -> cold)
    """
    tag_key = intent.replace("SUGGEST_", "").lower()
    
    items = filter_products_by_tag(tag_key)
    
    if items:
        friendly_names = {
            "cold": "mát lạnh", "hot": "nóng ấm", "sweet": "ngọt ngào", 
            "healthy": "healthy", "energy": "tỉnh táo", "less_sugar": "ít đường",
            "spicy": "cay nồng", "salty": "đậm đà", "cake": "bánh ngọt"
        }
        adjective = friendly_names.get(tag_key, tag_key)
        return f"✨ Gợi ý món {adjective} cho bạn:\n• " + "\n• ".join(items[:6])
        
    return f"Hiện tại quán chưa có món nào theo yêu cầu '{tag_key}' của bạn. Thử món khác nhé? 😊"

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    🔥 GENERIC LABELS ARCHITECTURE (Dynamic Handling)
    """
    message = request.message.strip()
    if not message:
        return ChatResponse(response="Bạn muốn hỏi gì về menu? 😊")
    
    intent, confidence = classify_with_phobert(message)
    extracted_entity = None
    response = ""
    
    product_check = extract_product_entity(message)
    if product_check and intent not in ["GREETING", "THANKS", "GET_MENU", "GET_CATEGORY"]:
        intent = "ASK_PRICE"
    
    if intent == "GREETING":
        response = handle_greeting()
    
    elif intent == "THANKS":
        response = handle_thanks()
    
    elif intent == "GET_MENU":
        response = handle_get_menu()
    
    elif intent == "GET_CATEGORY":
        response, extracted_entity = handle_get_category(message)
    
    elif intent == "ASK_PRICE":
        response, extracted_entity = handle_ask_price(message)
        
    elif intent == "OTHER":
        response = handle_other(message)
        
    elif intent.startswith("SUGGEST_"):
        response = handle_suggestion(intent)
    
    else:
        response = handle_other(message)
    
    return ChatResponse(
        response=response,
        intent=intent,
        confidence=round(confidence, 3),
        extracted_entity=extracted_entity
    )

@app.get("/")
async def root():
    return {
        "name": "Coffee Shop AI API - Generic Labels Architecture",
        "model": "PhoBERT Fine-tuned (12 generic labels)",
        "architecture": "Model understands INTENT → Entity Extraction finds WHAT → DB provides DATA",
        "labels": GENERIC_LABELS,
        "categories": len(MENU_DATA),
        "products": len(ALL_PRODUCTS),
        "advantage": "Change menu/prices = only update DB, NO RETRAINING needed!"
    }

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "phobert_loaded": phobert_classifier is not None,
        "num_labels": len(GENERIC_LABELS),
        "num_categories": len(MENU_DATA),
        "num_products": len(ALL_PRODUCTS)
    }

@app.get("/labels")
async def get_labels():
    return {
        "total": len(GENERIC_LABELS),
        "labels": GENERIC_LABELS,
        "description": {
            "GREETING": "User says hello",
            "THANKS": "User says thank you",
            "GET_MENU": "User asks for full menu",
            "GET_CATEGORY": "User asks about specific category (entity extracted)",
            "ASK_PRICE": "User asks about price (product extracted)",
            "SUGGEST_COLD": "User wants cold drinks",
            "SUGGEST_HOT": "User wants hot drinks",
            "SUGGEST_SWEET": "User wants sweet items",
            "SUGGEST_HEALTHY": "User wants healthy options",
            "SUGGEST_ENERGY": "User wants energy boost",
            "SUGGEST_LESS_SUGAR": "User wants less sugar",
            "OTHER": "Fallback for unclear intent"
        }
    }

@app.get("/categories")
async def get_categories():
    """List all categories with their keywords."""
    return {
        "categories": [
            {
                "key": key,
                "displayName": data['displayName'],
                "keywords": [k for k, v in CATEGORY_KEYWORDS.items() if v == key],
                "productCount": len(data['products'])
            }
            for key, data in MENU_DATA.items()
        ]
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
