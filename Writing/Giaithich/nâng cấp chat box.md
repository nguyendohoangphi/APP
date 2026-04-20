# 🚀 KẾ HOẠCH NÂNG CẤP CHAT BOX (PhoBERT AI Engine)

> **Ngày lập:** 07/04/2026  
> **Dự án:** CoffeeApp - PhiNoM AI Chatbot  
> **File engine:** `C:\Users\Administrator\AndroidStudioProjects\ai-engine\main.py`  
> **Model:** `phobert_final_clean`  
> **Dataset:** `dataset.xlsx`

---

## 🔍 VẤN ĐỀ HIỆN TẠI

Model PhoBERT đang classify **SAI INTENT** cho nhiều trường hợp thực tế:

| Câu người dùng | Intent đúng | Intent model đoán | Hậu quả |
|---|---|---|---|
| `"ban khoe ko"` | `OTHER` | `SUGGEST_CREAM` ❌ | Gợi ý món cream vô lý |
| `"cap he ay"` | `GET_CATEGORY` (coffee) | `GREETING` ❌ | Chào hỏi lại |
| `"ca phe ay"` | `GET_CATEGORY` (coffee) | `THANKS` ❌ | "Không có chi!" - vô nghĩa |
| `"cho tui xem thuc don"` | `GET_MENU` | `SUGGEST_COFFEE` ❌ | Gợi ý coffee thay vì menu |

### Nguyên nhân gốc rễ:

1. **Dataset thiếu câu không dấu / viết tắt kiểu telex**  
   → Model train chủ yếu câu có dấu chuẩn, khi user nhắn `"ca phe"`, `"tra sua"`, `"banh ngot"` thì bị sai

2. **Dataset thiếu câu `OTHER` đa dạng**  
   → Các câu không liên quan menu (hỏi thăm, nói chuyện) bị map nhầm sang SUGGEST_*

3. **Confidence threshold chưa có**  
   → Khi model không chắc chắn vẫn trả kết quả, không fallback về `OTHER`

---

## 🎯 MỤC TIÊU SAU KHI NÂNG CẤP

- ✅ AI hiểu câu **không dấu / viết tắt** (ca phe, tra sua, banh, nuoc ep...)
- ✅ AI trả lời đúng khi câu **không liên quan menu** (hỏi thăm, chat chit)
- ✅ AI nhận diện đúng intent với **confidence cao hơn**
- ✅ Có **fallback thông minh** khi confidence thấp

---

## 📋 KẾ HOẠCH THỰC HIỆN (Hướng 2 - Triệt Để)

---

### BƯỚC 1: Phân tích dataset hiện tại

**File:** `C:\Users\Administrator\AndroidStudioProjects\ai-engine\dataset.xlsx`

Kiểm tra:
- Tổng số mẫu hiện tại mỗi label
- Tỷ lệ câu có dấu vs không dấu
- Label nào đang thiếu mẫu (dưới 50 mẫu là nguy hiểm)

**Lệnh để xem nhanh:**
```python
import pandas as pd
df = pd.read_excel("dataset.xlsx")
print(df['intent'].value_counts())
print(f"Tổng: {len(df)} mẫu")
```

---

### BƯỚC 2: Bổ sung dataset - Phần câu KHÔNG DẤU

Thêm **ít nhất 30-50 câu không dấu** cho mỗi intent chính:

#### 2a. Label: `GET_CATEGORY` - Câu không dấu về cà phê
```
ca phe gi ngon, ca phe co gi, cho xem ca phe, ca phe ay, 
show ca phe, menu ca phe, cf nao ngon, muon uong cf
```

#### 2b. Label: `GET_CATEGORY` - Câu không dấu về trà, nước ép, bánh...
```
tra sua co gi, banh ngot nao ngon, nuoc ep gi, da xay co gi,
socola co mon gi, show banh di, tra gi ngon
```

#### 2c. Label: `GET_MENU` - Câu không dấu xem menu
```
thuc don co gi, cho xem menu, list mon di, menu ma, 
co gi an khong, quan co gi
```

#### 2d. Label: `OTHER` - Câu KHÔNG liên quan menu (RẤT QUAN TRỌNG)
```
ban co khoe khong, ban ten gi, hom nay dep khong,
toi nong qua (nếu không map được suggest_cold),
ban oi, hello ban, ban lam gi day, chao buoi sang,
tui buon qua, tui met qua, ngoai troi dep, 
ban biet gi khong, the nao, ok nha
```

#### 2e. Label: `SUGGEST_COLD` - Câu muốn uống lạnh (thêm pattern "nóng")
```
tui nong qua, nong lam, nong the, troi nong, 
muon gi lanh, do lanh di, mat lanh nhe,
uong gi lanh lanh, khat nuoc
```

#### 2f. Label: `GREETING` - Chỉ câu chào hỏi THỰC SỰ
```
hello, hi, chao, xin chao, alo, hey
```
> ⚠️ KHÔNG thêm câu hỏi thăm sức khỏe vào GREETING → để vào OTHER

---

### BƯỚC 3: Augmentation dữ liệu tự động

Tạo script để tự động sinh thêm câu từ câu gốc:

```python
# Script: augment_dataset.py
# Đặt tại: C:\Users\Administrator\AndroidStudioProjects\ai-engine\

import pandas as pd

def remove_accents(text):
    """Chuyển câu có dấu → không dấu"""
    import unicodedata
    # Map bảng chữ cái tiếng Việt → không dấu
    accent_map = {
        'à':'a','á':'a','ả':'a','ã':'a','ạ':'a',
        'ă':'a','ằ':'a','ắ':'a','ẳ':'a','ẵ':'a','ặ':'a',
        'â':'a','ầ':'a','ấ':'a','ẩ':'a','ẫ':'a','ậ':'a',
        'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e',
        'ê':'e','ề':'e','ế':'e','ể':'e','ễ':'e','ệ':'e',
        'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
        'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o',
        'ô':'o','ồ':'o','ố':'o','ổ':'o','ỗ':'o','ộ':'o',
        'ơ':'o','ờ':'o','ớ':'o','ở':'o','ỡ':'o','ợ':'o',
        'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u',
        'ư':'u','ừ':'u','ứ':'u','ử':'u','ữ':'u','ự':'u',
        'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y',
        'đ':'d',
        'À':'A','Á':'A','Ả':'A','Ã':'A','Ạ':'A',
        'Đ':'D'
    }
    result = ''
    for char in text:
        result += accent_map.get(char, char)
    return result

# Đọc dataset gốc
df = pd.read_excel("dataset.xlsx")

# Tạo bản không dấu cho mỗi câu
df_no_accent = df.copy()
df_no_accent['text'] = df_no_accent['text'].apply(remove_accents)

# Ghép lại
df_augmented = pd.concat([df, df_no_accent], ignore_index=True)
df_augmented = df_augmented.drop_duplicates(subset=['text'])
df_augmented.to_excel("dataset_augmented.xlsx", index=False)
print(f"Tăng từ {len(df)} → {len(df_augmented)} mẫu")
```

---

### BƯỚC 4: Retrain PhoBERT

Dùng notebook: `C:\Users\Administrator\AndroidStudioProjects\ai-engine\train_phobert.ipynb`

**Thay đổi cần làm trong notebook:**
1. Đổi đường dẫn dataset → `dataset_augmented.xlsx` (hoặc file mới)
2. Đổi output model path → `phobert_v2` (giữ lại `phobert_final_clean` để rollback)
3. Tăng epochs nếu cần (thường 5-10 epochs)
4. Theo dõi metrics: accuracy, f1-score từng label

**Config gợi ý khi retrain:**
```python
EPOCHS = 10
BATCH_SIZE = 16
LEARNING_RATE = 2e-5
MAX_LEN = 128
MODEL_SAVE_PATH = "phobert_v2"
DATASET_PATH = "dataset_augmented.xlsx"
```

---

### BƯỚC 5: Cập nhật `main.py` - Thêm confidence threshold

Sau khi retrain xong, cập nhật logic trong `main.py`:

```python
# Thêm vào hàm chat() - sau khi classify
CONFIDENCE_THRESHOLD = 0.65  # Nếu confidence < 65% → fallback về OTHER

intent, confidence = classify_with_phobert(message)

# Nếu confidence thấp → không tin model
if confidence < CONFIDENCE_THRESHOLD:
    intent = "OTHER"
    print(f"⚠️ Low confidence ({confidence:.2%}), fallback to OTHER")
```

---

### BƯỚC 6: Cập nhật `main.py` - Thêm pre-processing

Thêm bước normalize text trước khi đưa vào model:

```python
def preprocess_message(message: str) -> str:
    """Normalize message trước khi classify"""
    msg = message.strip().lower()
    
    # Map các từ viết tắt phổ biến
    abbreviations = {
        'cf': 'cà phê',
        'cf nao': 'cà phê nào',
        'tra sua': 'trà sữa', 
        'da xay': 'đá xay',
        'banh': 'bánh',
        'nuoc ep': 'nước ép',
        'ko': 'không',
        'ntn': 'như thế nào',
        'dc': 'được',
        'mk': 'mình',
        'mn': 'mọi người',
        'ck': 'chúc',
    }
    
    for abbr, full in abbreviations.items():
        msg = msg.replace(abbr, full)
    
    return msg

# Trong hàm chat():
message = preprocess_message(request.message.strip())
```

---

### BƯỚC 7: Đổi model path trong `main.py`

Sau khi verify model v2 hoạt động tốt:

```python
# Dòng 34 trong main.py - đổi từ:
PHOBERT_MODEL_PATH = "phobert_final_clean"

# Thành:
PHOBERT_MODEL_PATH = "phobert_v2"
```

---

### BƯỚC 8: Test lại toàn bộ các case lỗi

Sau khi deploy model mới, test lại các câu từ ảnh:

```bash
# Test bằng curl hoặc Postman
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "cap he ay"}'

# Expected: intent = GET_CATEGORY, response về coffee

curl -X POST http://localhost:8000/chat \
  -d '{"message": "ca phe ay"}'
# Expected: intent = GET_CATEGORY, response về coffee

curl -X POST http://localhost:8000/chat \
  -d '{"message": "ban khoe ko"}'
# Expected: intent = OTHER, response = fallback message

curl -X POST http://localhost:8000/chat \
  -d '{"message": "cho tui xem thuc don"}'
# Expected: intent = GET_MENU, response = full menu
```

---

## 📁 DANH SÁCH FILE SẼ THAY ĐỔI

| File | Thay đổi |
|---|---|
| `ai-engine/dataset.xlsx` | Bổ sung thêm câu không dấu + câu OTHER |
| `ai-engine/dataset_augmented.xlsx` | File mới - sau khi augment |
| `ai-engine/augment_dataset.py` | Script mới - augmentation |
| `ai-engine/phobert_v2/` | Thư mục model mới sau retrain |
| `ai-engine/main.py` | Thêm confidence threshold + preprocess |
| `ai-engine/train_phobert.ipynb` | Cập nhật path và config |

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **KHÔNG xóa `phobert_final_clean`** cho đến khi test v2 ổn định  
2. **Commit dataset gốc lên git** trước khi sửa  
3. Retrain mất khoảng **30-60 phút** tùy GPU/CPU  
4. Nếu chạy CPU: giảm batch_size xuống 8 để tránh out of memory  
5. Sau retrain, **kiểm tra f1-score từng label** trong notebook để xác nhận model tốt hơn  

---

## 🔄 KHI NÀO CẦN ROLLBACK?

Nếu model v2 tệ hơn v1:
```python
# main.py dòng 34 - rollback về:
PHOBERT_MODEL_PATH = "phobert_final_clean"
```

---

*Tạo bởi: Antigravity AI | Dự án: PhiNoM Coffee App*
