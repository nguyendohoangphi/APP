# BÁO CÁO QUY TRÌNH TÍCH HỢP AI CHATBOT – PHOBERT FINE-TUNING (GENERIC LABELS)

## 1. Tổng Quan (Overview)

### 1.1. Mục tiêu
Xây dựng **AI Chatbot** thông minh, linh hoạt với kiến trúc **Generic Labels**:
- Phân loại ý định người dùng (Intent Classification) dựa trên 30 nhãn mục đích chung.
- Không phụ thuộc vào tên sản phẩm cụ thể trong model (Model-Agnostic to Product Names).
- Tư vấn đồ uống động dựa trên tags (ví dụ: "mát lạnh", "ít đường", "tỉnh táo").
- Tự động cập nhật kiến thức khi menu thay đổi mà không cần huấn luyện lại model.

### 1.2. Giải pháp
Sử dụng kỹ thuật **Fine-tuning** mô hình **PhoBERT** (pre-trained model cho tiếng Việt) kết hợp với thuật toán **Entity Extraction** và **Dynamic Lookup**.

---

## 2. Công Nghệ Sử Dụng (Tech Stack)

### A. Mô Hình AI (AI Model)

| Thành phần | Mô tả |
|------------|-------|
| **Base Model** | `vinai/phobert-base` – Mô hình BERT pre-trained cho tiếng Việt (135M tham số) |
| **Task** | Text Classification (Phân loại văn bản) |
| **Architecture** | RoBERTa-based Sequence Classification |
| **Output** | **30 Generic Labels** (e.g., `SUGGEST_COLD`, `ASK_PRICE`, `GET_MENU`) |

### B. Framework & Libraries

| Library | Phiên bản | Mục đích |
|---------|-----------|----------|
| `transformers` | 4.x | Hugging Face Transformers – Load và train PhoBERT |
| `torch` | 2.x | PyTorch – Framework deep learning |
| `pandas` | 2.x | Xử lý dữ liệu Excel/CSV |
| `scikit-learn` | 1.x | LabelEncoder, train_test_split |
| `FastAPI` | 0.100+ | Backend server REST API hiệu năng cao |
| `uvicorn` | 0.x | ASGI server chạy FastAPI |

### C. Môi Trường

| Môi trường | Mục đích |
|------------|----------|
| **Google Colab** | Training model (GPU Tesla T4 miễn phí) |
| **Windows Local** | Chạy AI Server (FastAPI) |
| **Flutter App** | Giao diện người dùng Chat |

---

## 3. Kiến Trúc Hệ Thống (System Architecture)

Hệ thống hoạt động theo cơ chế **Hybrid** (AI Classification + Rule-based Entity Extraction):

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ChatScreen (chat_screen.dart)          │   │
│  └─────────────────────────┬───────────────────────────┘   │
│                            │ HTTP POST /chat               │
│                            ▼                               │
59: └────────────────────────────┼───────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          FASTAPI SERVER (Python)                        │
│                                                                         │
│  1. RECEIVE MESSAGE ──► "Cho mình một ly nào mát lạnh đi"               │
│                               │                                         │
│                               ▼                                         │
│  2. PHOBERT CLASSIFY ─► Intent: SUGGEST_COLD (Confidence: 98%)          │
│                               │                                         │
│                               ▼                                         │
│  3. BUSINESS LOGIC ───► Extract Tag: "cold"                             │
│       (main.py)       │ Lookup Data: Filter products with tag "cold"    │
│                       │ (Data source: data.js loaded in memory)         │
│                               │                                         │
│                               ▼                                         │
│  4. RESPONSE ─────────► "✨ Gợi ý món mát lạnh cho bạn:..."             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Quy Trình Thực Hiện Chi Tiết

### Bước 1: Chuẩn Bị Dataset & Generic Labels

#### 1.1. Chiến lược Generic Labels
Thay vì train model với tên món cụ thể (như `order_cappuccino`), ta train model để nhận diện **thuộc tính** món ăn. Điều này giúp model bền vững khi menu thay đổi.

**Danh sách 30 Labels:**
- **General:** `GREETING`, `THANKS`, `OTHER`
- **Query:** `GET_MENU`, `GET_CATEGORY`, `ASK_PRICE`
- **Suggestion (Tags):** `SUGGEST_COLD`, `SUGGEST_HOT`, `SUGGEST_SWEET`, `SUGGEST_LESS_SUGAR`, `SUGGEST_HEALTHY`, `SUGGEST_ENERGY`, `SUGGEST_COFFEE`, `SUGGEST_TEA`, ... (total 24 generic suggestion tags)

#### 1.2. Cấu trúc Training Data (`dataset.xlsx`)

| Input Text (Câu nói) | Label (Nhãn) | Giải thích |
|----------------------|--------------|------------|
| "tư vấn món nào mát lạnh đi" | `SUGGEST_COLD` | Người dùng muốn đồ lạnh |
| "đang buồn ngủ quá" | `SUGGEST_ENERGY` | Cần tỉnh táo (Coffee/Energy) |
| "giá của món Matcha Freeze là bao nhiêu" | `ASK_PRICE` | Hỏi giá (Entity: Matcha Freeze) |
| "menu quán có gì" | `GET_MENU` | Hỏi menu |

---

### Bước 2: Fine-tuning trên Google Colab

#### 2.1. Notebook Training
Sử dụng file `train_phobert_generic.ipynb` để huấn luyện.

```python
# Cấu hình Training
training_args = TrainingArguments(
    output_dir='./results',
    num_train_epochs=10,          # Tăng lên 10 epochs để model học sâu hơn
    per_device_train_batch_size=16,
    learning_rate=2e-5,
    save_strategy="no",           # Chỉ lưu model cuối cùng để tiết kiệm dung lượng
    fp16=True                     # Tăng tốc độ train
)
```

#### 2.2. Kết quả Training
- **Dataset size**: ~1500 mẫu câu đa dạng.
- **Accuracy**: > 90%
- **Ưu điểm**: File model sau khi clean (`phobert_final_clean`) chỉ nặng ~400MB, dễ dàng deploy.

---

### Bước 3: Backend Server & Logic Xử Lý (`main.py`)

Backend không chỉ đơn thuần gọi model, mà còn chứa logic thông minh để xử lý dữ liệu động.

#### 3.1. Smart Priority Logic (Logic Ưu Tiên)
Một cải tiến quan trọng để tránh AI trả lời máy móc:
*Nếu người dùng nhắc đến tên sản phẩm cụ thể, hệ thống sẽ ưu tiên trả lời chi tiết sản phẩm đó thay vì gợi ý chung chung.*

```python
# main.py snippet
intent, confidence = classify_with_phobert(message)

# 🔥 PRIORITIZE PRODUCT ENTITY
# Nếu user hỏi "Berry Freeze như thế nào", dù model đoán là SUGGEST_FREEZE
# Hệ thống vẫn sẽ ép về ASK_PRICE để hiển thị chi tiết món Berry Freeze.
product_check = extract_product_entity(message)
if product_check and intent not in ["GREETING", "THANKS", "GET_MENU", "GET_CATEGORY"]:
    intent = "ASK_PRICE"
```

#### 3.2. Dynamic Suggestion Handler
Xử lý các intent `SUGGEST_*` bằng cách map với tags trong database.

```python
def handle_suggestion(intent: str) -> str:
    # Intent: SUGGEST_COLD -> Tag: "cold"
    tag_key = intent.replace("SUGGEST_", "").lower()
    
    # Tìm kiếm trong MENU_DATA (load từ data.js)
    items = filter_products_by_tag(tag_key)
    
    return f"✨ Gợi ý món {tag_key} cho bạn:\n" + "\n".join(items)
```

---

### Bước 4: Kiểm Thử Thực Tế

| Trường hợp | Input User | AI Xử Lý | Kết quả |
|------------|------------|----------|---------|
| **Hỏi chung** | "Uống gì cho tỉnh táo?" | Intent: `SUGGEST_ENERGY` | List các món Cafe đen, Phin sữa đá... |
| **Hỏi cụ thể** | "Bạc Xỉu giá bao nhiêu?" | Intent: `ASK_PRICE` + Entity: "Bạc Xỉu" | "🏷️ Bạc Xỉu: 29.000đ" |
| **Fallback** | "Ly này ngon không" (kèm tên món) | Intent: `OTHER` -> Detect Product | Tự chuyển sang giới thiệu món đó. |

---

## 5. Thuật Ngữ Chuyên Ngành (Glossary)

| Thuật ngữ | Tiếng Việt | Giải thích |
|-----------|------------|------------|
| **Fine-tuning** | Tinh chỉnh | Huấn luyện thêm model pre-trained trên dữ liệu chuyên biệt (domain-specific data). |
| **Intent Classification** | Phân loại ý định | Bài toán xác định mục đích của câu văn bản. |
| **Named Entity Recognition (NER)** | Nhận diện thực thể | (Ở đây dùng rule-based) Kỹ thuật rút trích tên riêng (tên món ăn) từ câu. |
| **Pipeline** | Đường ống | Quy trình khép kín từ Input -> Tokenize -> Model -> Output. |
| **Generic Label** | Nhãn tổng quát | Cách gán nhãn dựa trên nhóm/loại thay vì đối tượng cụ thể. |

---

## 6. Kết Luận

### 6.1. Ưu điểm nổi bật
1.  **Dễ bảo trì**: Thêm món mới vào menu (file `data.js`) -> AI tự biết gợi ý ngay lập tức, **không cần train lại model**.
2.  **Chính xác**: Kết hợp sức mạnh hiểu ngôn ngữ của PhoBERT và độ chính xác tuyệt đối của Rule-based lookup.
3.  **Tốc độ**: Server phản hồi < 200ms.

### 6.2. Hướng phát triển
- Tích hợp Database thực (Firebase/SQL) thay vì load file tĩnh.
- Thêm ngữ cảnh hội thoại (Context-aware) để chat tự nhiên hơn (vẫn đang stateless).

---

## 7. File Liên Quan

| File | Đường dẫn | Mô tả |
|------|-----------|-------|
| `main.py` | `ai-engine/main.py` | FastAPI server + Logic xử lý |
| `dataset.xlsx` | `ai-engine/dataset.xlsx` | Dataset huấn luyện (Generic Labels) |
| `train_phobert_generic.ipynb` | `ai-engine/train_phobert_generic.ipynb` | Notebook huấn luyện model |
| `phobert_final_clean/` | `ai-engine/phobert_final_clean/` | Model đã fine-tune (Clean version) |
| `data.js` | `admin-web/public/data.js` | Dữ liệu gốc dùng cho cả Web & AI |
