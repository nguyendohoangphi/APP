# BÁO CÁO TÍNH NĂNG TÌM KIẾM CỬA HÀNG & CHỈ ĐƯỜNG (STORE LOCATOR & ROUTING)

Tài liệu này tổng hợp toàn bộ thông tin kiến trúc, thư viện, mã nguồn và các câu hỏi bảo vệ đồ án cho tính năng **Bản đồ - Tìm Cửa Hàng & Chỉ Đường nội bộ**.

---

## I. TỔNG QUAN TÍNH NĂNG

Tính năng Store Locator trên ứng dụng CoffeeApp đã được nâng cấp từ việc mở app ngoài sang trải nghiệm **Chỉ đường trực tiếp trong ứng dụng**:
1. **Định vị thực tế**: Sử dụng GPS thiết bị để xác định tọa độ người dùng thay vì dùng vị trí giả lập.
2. **Hiển thị trực quan**: Vẽ đường đi (Polyline) từ vị trí người dùng tới cửa hàng ngay trên bản đồ App.
3. **Lọc thông minh**: Tìm kiếm cửa hàng theo Tỉnh/Thành phố và Quận/Huyện.
4. **Tương tác**: Chấm xanh (User) và Chấm đỏ (Store) giúp người dùng dễ dàng định vị không gian.

---

## II. CÔNG NGHỆ VÀ THƯ VIỆN SỬ DỤNG (LIBRARIES)

Hệ thống sử dụng các giải pháp mã nguồn mở hoàn toàn miễn phí, không phụ thuộc vào Google Maps API Key trả phí:

1.  **`flutter_map`**: Engine chính để hiển thị bản đồ (tile-based). Sử dụng dữ liệu từ OpenStreetMap.
2.  **`geolocator`**: Thư viện giao tiếp với phần cứng (GPS) của Android/iOS để lấy tọa độ thực thời gian thực.
3.  **`latlong2`**: Xử lý đại số và cấu trúc dữ liệu tọa độ (Latitude/Longitude).
4.  **`http`**: Dùng để gọi API tới Server tìm đường.
5.  **OSRM (Open Source Routing Machine) API**: Công cụ tính toán đường đi ngắn nhất dựa trên dữ liệu giao thông thực tế.
6.  **`cloud_firestore`**: Lưu trữ dữ liệu danh sách cửa hàng tập trung trên Cloud.

---

## III. VỊ TRÍ FILE & CẤU TRÚC HỆ THỐNG

### 1. Vị trí mã nguồn:
- **Giao diện & Logic chính**: `lib/screens/Store/store_locator_screen.dart`
- **Model dữ liệu**: `lib/models/store.dart`
- **Cấu hình quyền (Android)**: `android/app/src/main/AndroidManifest.xml` (Thêm `ACCESS_FINE_LOCATION`)
- **Cấu hình quyền (iOS)**: `ios/Runner/Info.plist` (Thêm `NSLocationWhenInUseUsageDescription`)

---

## IV. CÁC HÀM VÀ THUẬT TOÁN CHÍNH (CORE FUNCTIONS)

### 1. Hàm tự viết (Custom Logic):
- **`_determinePosition()`**: 
    - **Nhiệm vụ**: Kiểm tra quyền truy cập vị trí, bật dịch vụ GPS và lấy tọa độ hiện tại.
    - **Logic**: Sử dụng `Geolocator.getCurrentPosition`. Nếu thành công, cập nhật biến `userLocation` và di chuyển camera bản đồ về vị trí người dùng.
- **`_getRoute(LatLng destination)`**:
    - **Nhiệm vụ**: Tính toán và vẽ đường đi.
    - **Thuật toán**: Gọi tới API của OSRM. API này sử dụng thuật toán **Dijkstra** hoặc **CH (Contraction Hierarchies)** trên đồ thị giao thông để tìm đường đi ngắn nhất cho xe ô tô/xe máy.
    - **Kết quả**: Giải mã (Decode) chuỗi tọa độ trả về thành mảng `routePoints` và vẽ lên `PolylineLayer`.
- **`_mapController.fitCamera()`**: Tự động tính toán mức Zoom để hiển thị trọn vẹn cả điểm đi (User) và điểm đến (Store) trong một khung hình.

### 2. Hàm gọi từ thư viện (Third-party):
- **`TileLayer`**: Gọi dữ liệu hình ảnh bản đồ từ máy chủ OpenStreetMap.
- **`MarkerLayer`**: Vẽ các icon ghim lên bản đồ dựa trên tọa độ Lat/Lng.

---

## V. CÁC CÂU HỎI GIÁO VIÊN THƯỜNG HỎI (Q&A)

**❓ Câu 1: Tại sao em không dùng Google Maps SDK cho nhanh mà lại dùng Flutter Map + OSRM?**
> **Trả lời:** Dạ, Google Maps SDK yêu cầu khai báo thẻ tín dụng và tính phí sau một hạn mức nhất định. Giải pháp **Flutter Map + OSRM** của em hoàn toàn miễn phí, mã nguồn mở và giúp em làm chủ được dữ liệu. Việc tích hợp API OSRM cũng chứng minh em có khả năng xử lý dữ liệu mạng (HTTP) và giải mã các cấu trúc dữ liệu phức tạp như GeoJSON để vẽ đường đi, thay vì chỉ gọi một ứng dụng có sẵn.

**❓ Câu 2: Thuật toán tìm đường hoạt động như thế nào? App có tự tính toán được không?**
> **Trả lời:** Dạ, việc tính toán đường đi trên đồ thị giao thông khổng lồ rất nặng nên em sử dụng **Service OSRM**. Quy trình là: App gửi Tọa độ A và B lên Server OSRM -> Server thực hiện thuật toán tìm đường trên dữ liệu bản đồ thế giới -> Trả về danh sách hàng nghìn tọa độ nối tiếp nhau tạo thành đường đi -> App nhận về và dùng `PolylineLayer` để nối các điểm đó lại thành sợi dây định hướng trên màn hình.

**❓ Câu 3: Làm thế nào em đảm bảo quyền riêng tư của người dùng khi lấy vị trí?**
> **Trả lời:** Dạ, em đã cấu hình quyền ở mức **"Khi đang sử dụng ứng dụng" (When in use)** trong `AndroidManifest.xml` và `Info.plist`. App luôn kiểm tra quyền trước khi truy cập GPS. Nếu người dùng từ chối, App sẽ hiện thông báo nhắc nhở thay vì tự ý truy cập ngầm, đảm bảo đúng tiêu chuẩn về bảo mật của Google và Apple.

**❓ Câu 4: Nếu người dùng không bật GPS thì App có hoạt động được không?**
> **Trả lời:** Dạ có ạ. Nếu không có GPS, App sẽ sử dụng `initialCenter` mặc định hoặc tự động nhảy đến vị trí của cửa hàng đầu tiên trong danh sách giúp người dùng vẫn xem được thông tin chi nhánh. Em cũng thiết kế nút "Locate Me" để người dùng có thể kích hoạt lại việc dò vị trí bất cứ lúc nào tâm lý họ sẵn sàng.

**❓ Câu 5: Em giải quyết thế nào nếu lộ trình tìm đường quá dài làm người dùng khó quan sát?**
> **Trả lời:** Dạ, em sử dụng hàm `_mapController.fitCamera` kết hợp với `LatLngBounds`. Hàm này sẽ tự động thu nhỏ (Zoom Out) bản đồ vừa đủ để điểm đầu và điểm cuối luôn nằm trong khung nhìn của điện thoại, giúp người dùng có cái nhìn tổng thể về lộ trình trước khi di chuyển.
