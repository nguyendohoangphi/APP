# Phân Tích Hệ Thống Chi Tiết: Admin Web (Node.js + Firebase)

Tài liệu phân tích kỹ thuật hệ thống quản trị website, dành cho lập trình viên muốn **HIỂU RÕ MÃ NGUỒN**.

---

# PHASE 1 — SƠ ĐỒ TỔNG QUAN
### 1. Sơ đồ kiến trúc tổng thể (Global Architecture)

Hệ thống được cấu thành từ 3 mảnh ghép chính, xoay quanh Google Firebase.

```mermaid
graph TD
    subgraph "FRONTEND (Client Side)"
        Teacher[Giảng Viên/Sinh Viên] -->|Thao tác| MobileApp[📱 Mobile App (Flutter)]
        AdminUser[Quản Trị Viên] -->|Thao tác| AdminWeb[🖥️ Admin Web (Node.js/HTML)]
    end

    subgraph "BACKEND SERVICES (Server Side)"
        direction TB
        Firebase{🔥 Google Firebase}
        AI_Server[🧠 AI Engine (Python FastAPI)]
    end

    %% Luồng dữ liệu Flutter
    MobileApp <-->|1. Real-time Database| Firebase
    MobileApp <-->|2. Chat & Gợi ý| AI_Server
    
    %% Luồng dữ liệu Admin
    AdminWeb <-->|3. Quản lý Menu/User| Firebase
    AdminWeb -->|4. Upload Ảnh| Firebase

    %% Chi tiết Firebase
    Firebase -.-> Auth[(Authentication)]
    Firebase -.-> DB[(Firestore NoSQL)]
    Firebase -.-> Storage[(Cloud Storage)]
```

### Vai Trò
*   **Web Server (`server.js`):** Không chứa logic nghiệp vụ phức tạp. Chủ yếu để phục vụ file tĩnh (HTML/CSS) và nhận file upload từ admin.
*   **Client Side (`public/*.js`):** Chứa 90% logic. Admin Web này là dạng **SPA (Single Page Application)** giả lập. Logic sửa xóa món ăn chạy trực tiếp trên trình duyệt của Admin, gọi thẳng tới Firebase.

---

# PHASE 2 — PHÂN TÍCH CẤU TRÚC THƯ MỤC

Admin Web là một dự án Node.js (Backend) lai với Vanilla JS (Frontend).

```bash
admin-web/
├── node_modules/       # Thư viện tải về (Express, Multer...) - Không đụng vào
├── public/             # [Frontend] Chứa code chạy dưới Browser
│   ├── assets/         
│   │   ├── css/        # Style giao diện (Màu sắc, bố cục)
│   │   └── uploads/    # [QUAN TRỌNG] Nơi server lưu ảnh upload tạm thời
│   ├── auth.js         # Logic Đăng nhập & Check quyền Admin (Client-side)
│   ├── dashboard.js    # Logic vẽ biểu đồ thống kê (Chart.js)
│   ├── products.js     # Logic CRUD sản phẩm (Thêm/Sửa/Xóa/Tìm kiếm)
│   ├── devtools.js     # Tool ẩn Developer (Xóa nhanh, Seed data)
│   ├── firebase-config.js # Chứa Key kết nối Firebase (API Key, Project ID)
│   └── index.html...   # Các file giao diện HTML
├── server.js           # [Backend] Server Node.js, API Upload ảnh
├── package.json        # Khai báo dependency (express, multer...)
└── .env                # Biến môi trường (Secret Key)
```

---

# PHASE 3 — REVIEW FILE THEO CHIỀU SÂU (CHI TIẾT MÃ NGUỒN)

Phần này đi sâu vào **Code thực tế**, giải thích logic quan trọng.

> [!NOTE]
> **Quy ước:**
> *   **Frontend:** Code chạy trên trình duyệt (trong folder `public/`).
> *   **Backend:** Code chạy trên Server (file `server.js`).

## 1. Kết Nối & Cấu Hình

### `public/firebase-config.js`
*   **Mục đích:** Khởi tạo kết nối Firebase cho Frontend.
*   **Code Chi Tiết:**
```javascript
// File: public/firebase-config.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

const firebaseConfig = {
    apiKey: "AIzaSyCHVY4...", // Key public (an toàn trên client nếu chỉnh Rules chuẩn)
    projectId: "phinom-coffee",
    // ...
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app); // Export DB để các file khác dùng
const auth = getAuth(app);    // Export Auth

export { db, app, auth };
```

## 2. Server Backend (Node.js)

### `server.js`
*   **Mục đích:** Serve web tĩnh và Xử lý upload file ảnh (vì Firestore Client không lưu file trực tiếp được).
*   **Logic Chi Tiết - API Upload:**

```javascript
// File: server.js
const express = require('express');
const multer = require('multer'); // Thư viện xử lý upload file

// A. Cấu hình nơi lưu file (Lưu vào ổ cứng server)
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'public/assets/uploads'),
    filename: (req, file, cb) => {
        // Đặt tên file = Timestamp + Tên gốc -> Tránh trùng lặp
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + '-' + file.originalname);
    }
});
const upload = multer({ storage: storage });

// B. API Endpoint: POST /upload
app.post('/upload', upload.single('image'), (req, res) => {
    if (!req.file) return res.status(400).send('No file uploaded.');
    
    // Trả về đường dẫn tương đối (để client lưu vào Firestore)
    // VD: assets/uploads/17000000-cafe.jpg
    res.json({ path: 'assets/uploads/' + req.file.filename });
});
```

## 3. Quản Lý Sản Phẩm (Frontend)

### `public/products.js`
*   **Nhiệm vụ:** CRUD (Create, Read, Update, Delete) sản phẩm trên Firestore.
*   **Logic Chi Tiết:**

**1. Tải Danh Sách Sản Phẩm (Read):**
```javascript
// Hàm: loadProducts
// Tại: public/products.js
async function loadProducts() {
    // A. Gọi API Firestore lấy toàn bộ collection "Products"
    const querySnapshot = await getDocs(collection(db, "Products"));

    // B. Duyệt qua từng doc để tạo mảng dữ liệu
    allProducts = [];
    querySnapshot.forEach(doc => {
        allProducts.push({ id: doc.id, ...doc.data() });
    });

    // C. Vẽ UI (Render Table HTML)
    renderTable(allProducts);
}
```

**2. Thêm Sản Phẩm Mới (Create):**
```javascript
// Sự kiện: form.onsubmit
// Tại: public/products.js
form.onsubmit = async (e) => {
    e.preventDefault();

    // A. Thu thập dữ liệu từ Form
    const productData = {
        name: document.getElementById('p-name').value,
        price: parseFloat(document.getElementById('p-price').value),
        type: document.getElementById('p-category').value,
        imageUrl: document.getElementById('p-image').value, // URL ảnh (đã upload trước đó)
        createDate: new Date().toISOString(),
        rating: 5.0 // Mặc định 5 sao
    };

    // B. Gửi lệnh tạo document mới lên Firestore
    if (!isEditMode) {
        await addDoc(collection(db, "Products"), productData);
        alert("Thêm sản phẩm thành công!");
    } 
    // ... (Logic Edit tương tự dùng updateDoc)
};
```

**3. Xóa Sản Phẩm (Delete):**
```javascript
// Hàm: deleteProduct
// Tại: public/products.js
async function deleteProduct(id) {
    if (confirm('Bạn có chắc chắn muốn xóa?')) {
        // Gọi lệnh xóa trực tiếp theo ID
        await deleteDoc(doc(db, "Products", id));
        loadProducts(); // Reload lại bảng
    }
}
```

## 4. Bảo Mật & Xác Thực (Frontend)

### `public/auth.js`
*   **Nhiệm vụ:** Đăng nhập và kiểm tra quyền Admin.
*   **Logic Chi Tiết:**

**1. Xử lý Đăng Nhập:**
```javascript
// Sự kiện: loginForm.onsubmit
// Tại: public/auth.js
loginForm.onsubmit = async (e) => {
    // A. Đăng nhập qua Firebase Auth
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // B. Kiểm tra "Custom Claims" (Token đặc biệt)
    // Để xem user này có phải là Admin thật không (được gán từ server)
    const idTokenResult = await user.getIdTokenResult(true);

    if (idTokenResult.claims.admin) {
        window.location.href = '/'; // Vào trang chủ
    } else {
        alert("Bạn không phải Admin!");
        await signOut(auth); // Đá văng ra
    }
};
```

**2. Bảo vệ Route (Chặn truy cập trái phép):**
```javascript
// Logic chạy global
// Tại: public/auth.js
if (window.location.pathname !== '/login') {
    onAuthStateChanged(auth, (user) => {
        if (!user) {
            // Nếu chưa đăng nhập -> Chuyển về Login ngay lập tức
            window.location.href = '/login';
        }
        // Nếu đã đăng nhập -> Cho phép ở lại trang
    });
}
```

## 5. Thống Kê Dashboard

### `public/dashboard.js`
*   **Nhiệm vụ:** Tính toán số liệu và vẽ biểu đồ.
*   **Logic Chi Tiết:**

```javascript
// Hàm: loadDashboardStats
// Tại: public/dashboard.js
async function loadDashboardStats() {
    // A. Đếm tổng số sản phẩm (Dùng count server-side siêu nhanh)
    const prodSnapshot = await getCountFromServer(collection(db, "Products"));
    document.getElementById('total-products').textContent = prodSnapshot.data().count;

    // B. Tính tổng doanh thu (Phải tải tất cả đơn hàng về cộng tay - Cẩn thận nếu dữ liệu lớn)
    const orderSnapshot = await getDocs(collection(db, "Order"));
    let totalRevenue = 0;
    
    orderSnapshot.forEach(doc => {
        const data = doc.data();
        totalRevenue += parseFloat(data.total) || 0;
    });

    // C. Vẽ biểu đồ (Chart.js)
    renderCharts(orderSnapshot);
}
```

---

# PHASE 4 — HƯỚNG DẪN CONFIG & DEPLOY

### 1. Chuẩn bị Firebase
Để Admin Web chạy được, bạn cần đảm bảo:
*   Đã bật **Firestore Database**.
*   Đã bật **Authentication** (Email/Password).
*   Đã gán quyền Admin cho email của bạn (dùng tool hoặc script Node.js).

### 2. Lưu ý khi Deploy
Vì `server.js` lưu ảnh vào folder `public/assets/uploads` (ổ cứng server), nên:
*   **Nên dùng:** VPS, DigitalOcean Droplet (Ổ cứng vĩnh viễn).
*   **Không nên dùng:** Vercel, Render Free Tier, Heroku (Dữ liệu ổ cứng sẽ bị xóa sau mỗi lần restart).
    *   *Giải pháp:* Nếu dùng các host này, phải sửa code upload để đẩy ảnh lên **Firebase Storage** thay vì lưu local.
