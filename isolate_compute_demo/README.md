# Chủ đề 03: Xử lý tác vụ nặng với Isolate (hàm `compute`) để giữ mượt giao diện

Ứng dụng demo Flutter minh hoạ hiện tượng **UI Jank/Freeze** khi tính toán nặng trên Main Thread
và cách khắc phục bằng **Isolate** thông qua hàm `compute`.

## 1. Mô tả demo

Màn hình có hai hiệu ứng chuyển động liên tục (icon xoay bằng `AnimationController` và
`CircularProgressIndicator`) cùng 2 nút bấm thực hiện **cùng một tác vụ nặng**
(vòng lặp 200 triệu lần tính `sqrt(i) * sin(i)`):

| Nút | Cách chạy | Kết quả quan sát |
|---|---|---|
| Nút 1 (đỏ) | Gọi trực tiếp trên Main Thread | Animation **đứng hình** cho đến khi tính xong |
| Nút 2 (xanh) | `await compute(heavyComputation, n)` | Animation **vẫn quay mượt** |

Ứng dụng hiển thị thời gian tính toán để so sánh hai cách.

## 2. Yêu cầu môi trường

- Flutter SDK >= 3.10 (Dart >= 3.0). Kiểm tra bằng `flutter doctor`.
- Android Studio / VS Code, cùng một Emulator/Simulator hoặc thiết bị thật.

## 3. Cài đặt và chạy

Repo này chỉ chứa phần mã nguồn chính (`lib/`, `pubspec.yaml`). Nếu thư mục `android/`, `ios/`
chưa có, sinh chúng bằng lệnh sau (không ghi đè code hiện có):

```bash
git clone <URL-REPO-CUA-NHOM>
cd isolate_compute_demo
flutter create .          # sinh các thư mục nền tảng nếu thiếu
flutter pub get
flutter run --release     # nên dùng release để so sánh thời gian chính xác
```

Chạy trên thiết bị cụ thể: `flutter devices` rồi `flutter run -d <device_id> --release`.

> Lưu ý: chế độ **debug** chạy chậm hơn nhiều so với **release/profile**. Nếu tác vụ quá
> lâu hoặc quá nhanh, chỉnh hằng số `kIterations` trong `lib/main.dart`.

## 4. Biến môi trường / cấu hình

Ứng dụng demo **không cần** file `.env` hay `google-services.json`; không dùng API/Firebase.

## 5. Cấu trúc thư mục

```
isolate_compute_demo/
├── lib/
│   └── main.dart        # UI, hàm heavyComputation, 2 nút demo
├── pubspec.yaml
└── README.md
```

## 6. Ghi chú kỹ thuật

- Hàm đưa vào `compute` phải là **top-level hoặc static**; tham số và kết quả phải gửi được
  qua port (số, chuỗi, List, Map...).
- Isolate không chia sẻ bộ nhớ; dữ liệu được **sao chép** khi gửi/nhận.
- Trên **Flutter Web**, `compute` không tạo luồng thật mà chạy trên main thread, nên hãy demo
  trên Android/iOS/Desktop.

## 7. Thành viên và phân công

| Thành viên | MSSV | Nhiệm vụ |
|---|---|---|
| ... | ... | Giao diện + animation |
| ... | ... | Tác vụ nặng + `compute` |
| ... | ... | Slide thuyết trình |
| ... | ... | README, kiểm thử, quay demo |

Mỗi thành viên commit riêng theo nhiệm vụ, ví dụ:
`feat(ui): thêm animation xoay`, `feat(compute): thêm nút chạy bằng compute`,
`docs: viết README`.
