import { db } from './firebase-config.js';
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const storeList = document.getElementById('store-list');
const btnAddStore = document.getElementById('btn-add-store');
const addStoreModal = document.getElementById('addStoreModal');
const btnCloseModal = document.getElementById('btn-close-modal');
const addStoreForm = document.getElementById('addStoreForm');
const fileInput = document.getElementById('s-file');
const imageUrlInput = document.getElementById('s-image');
const loading = document.getElementById('loading');
const searchInput = document.getElementById('searchInput');

let stores = [];
let editingId = null;

const districtsByProvince = {
    "Hồ Chí Minh": ["Quận 1", "Quận 2", "Quận 3", "Quận 4", "Quận 5", "Quận 6", "Quận 7", "Quận 8", "Quận 9", "Quận 10", "Quận 11", "Quận 12", "Tân Bình", "Bình Thạnh", "Gò Vấp", "Phú Nhuận", "Tân Phú", "Bình Tân", "Thủ Đức", "Hóc Môn", "Củ Chi", "Nhà Bè", "Bình Chánh", "Cần Giờ"],
    "Hà Nội": ["Ba Đình", "Hoàn Kiếm", "Tây Hồ", "Cầu Giấy", "Đống Đa", "Hai Bà Trưng", "Thanh Xuân", "Nam Từ Liêm", "Bắc Từ Liêm", "Hà Đông", "Hoàng Mai", "Long Biên", "Thanh Trì", "Gia Lâm", "Sóc Sơn", "Đông Anh"],
    "Đà Nẵng": ["Hải Châu", "Thanh Khê", "Sơn Trà", "Ngũ Hành Sơn", "Cẩm Lệ", "Liên Chiểu", "Hòa Vang", "Hoàng Sa"]
};

// Handle Province Change Event
const sProvince = document.getElementById('s-province');
const sDistrict = document.getElementById('s-district');

if (sProvince && sDistrict) {
    sProvince.addEventListener('change', (e) => {
        const province = e.target.value;
        sDistrict.innerHTML = '<option value="">-- Chọn Quận/Huyện --</option>';
        if (districtsByProvince[province]) {
            districtsByProvince[province].forEach(district => {
                const opt = document.createElement('option');
                opt.value = district;
                opt.textContent = district;
                sDistrict.appendChild(opt);
            });
        }
    });
}


async function loadStores() {
    loading.style.display = 'block';
    storeList.innerHTML = '';
    try {
        const querySnapshot = await getDocs(collection(db, "stores"));
        stores = [];
        querySnapshot.forEach((doc) => {
            stores.push({ id: doc.id, ...doc.data() });
        });
        renderStores(stores);
    } catch (error) {
        console.error("Error fetching stores:", error);
        alert("Lỗi khi tải cửa hàng.");
    } finally {
        loading.style.display = 'none';
    }
}

function renderStores(dataList) {
    storeList.innerHTML = '';
    if (dataList.length === 0) {
        storeList.innerHTML = '<tr><td colspan="5" style="text-align:center;color:grey;padding:20px;">Không tìm thấy cửa hàng nào</td></tr>';
        return;
    }
    dataList.forEach(store => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>
                <img src="${store.image || 'assets/images/banner/firstbanner.jpg'}" alt="Cửa hàng" 
                     onerror="this.src='https://placehold.co/100?text=Cửa+Hàng'" 
                     style="width:80px; height:60px; object-fit:cover; border-radius:10px;">
            </td>
            <td><strong>${store.name}</strong></td>
            <td><small style="color:var(--text-grey);">${store.address}</small></td>
            <td>${store.district || '-'}, ${store.province || '-'}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn-icon btn-edit" title="Sửa"><span class="material-icons-round">edit</span></button>
                    <button class="btn-icon btn-delete" title="Xóa"><span class="material-icons-round">delete</span></button>
                </div>
            </td>
        `;

        tr.querySelector('.btn-edit').onclick = () => openModal(store);
        tr.querySelector('.btn-delete').onclick = () => deleteStore(store.id, store.name);
        
        storeList.appendChild(tr);
    });
}

function openModal(store = null) {
    if (store) {
        editingId = store.id;
        document.querySelector('.modal-content h2').textContent = "Cập nhật Cửa hàng";
        
        document.getElementById('s-name').value = store.name || '';
        document.getElementById('s-address').value = store.address || '';
        document.getElementById('s-province').value = store.province || '';
        if (sProvince) sProvince.dispatchEvent(new Event('change'));
        document.getElementById('s-district').value = store.district || '';
        document.getElementById('s-lat').value = store.lat || '';
        document.getElementById('s-lng').value = store.lng || '';
        document.getElementById('s-image').value = store.image || '';
    } else {
        editingId = null;
        document.querySelector('.modal-content h2').textContent = "Thêm Cửa hàng mới";
        addStoreForm.reset();
        document.getElementById('s-image').value = 'assets/images/banner/firstbanner.jpg';
    }
    addStoreModal.style.display = 'flex';
}

function closeModal() {
    addStoreModal.style.display = 'none';
    addStoreForm.reset();
    editingId = null;
}

if (btnAddStore) btnAddStore.onclick = () => openModal();
if (btnCloseModal) btnCloseModal.onclick = closeModal;

if (addStoreForm) {
    addStoreForm.onsubmit = async (e) => {
        e.preventDefault();
        const submitBtn = document.querySelector('#addStoreForm .btn-primary');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = "Đang xử lý...";

        try {
            const storeData = {
                name: document.getElementById('s-name').value.trim(),
                address: document.getElementById('s-address').value.trim(),
                province: document.getElementById('s-province').value.trim(),
                district: document.getElementById('s-district').value.trim(),
                lat: parseFloat(document.getElementById('s-lat').value) || 0,
                lng: parseFloat(document.getElementById('s-lng').value) || 0,
                image: document.getElementById('s-image').value.trim()
            };

            if (fileInput.files.length > 0) {
                const formData = new FormData();
                formData.append('image', fileInput.files[0]);
                const res = await fetch('/upload?folder=images/store', { method: 'POST', body: formData });
                if (res.ok) {
                    const data = await res.json();
                    storeData.image = data.path;
                }
            }

            if (editingId) {
                await updateDoc(doc(db, "stores", editingId), storeData);
            } else {
                await addDoc(collection(db, "stores"), storeData);
            }

            closeModal();
            loadStores();
        } catch (error) {
            console.error(error);
            alert("Lỗi khi lưu dữ liệu cửa hàng: " + error.message);
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    };
}

async function deleteStore(id, name) {
    if (!confirm(`Bạn có chắc chắn muốn xóa cửa hàng "${name}"? Thao tác này không thể hoàn tác.`)) {
        return;
    }
    
    try {
        await deleteDoc(doc(db, "stores", id));
        loadStores();
    } catch (error) {
        console.error(error);
        alert("Lỗi khi xóa: " + error.message);
    }
}

if (fileInput) {
    fileInput.onchange = () => {
        if (fileInput.files.length > 0) {
            imageUrlInput.value = "[Sẽ upload ảnh mới khi lưu]";
        }
    };
}

if (searchInput) {
    searchInput.addEventListener('input', (e) => {
        const val = e.target.value.toLowerCase().trim();
        const filtered = stores.filter(s => 
            s.name.toLowerCase().includes(val) || 
            (s.address && s.address.toLowerCase().includes(val)) ||
            (s.district && s.district.toLowerCase().includes(val))
        );
        renderStores(filtered);
    });
}

// Init
document.addEventListener('DOMContentLoaded', loadStores);
