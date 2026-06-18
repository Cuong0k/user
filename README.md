# Slag Clone — VPN client (Flutter + v2board/Xboard)

Dựng lại kiến trúc app **SlagClient** (`com.slaglab.slagclient`) đã phân tích từ APK,
kết nối thẳng vào panel v2board/Xboard của bạn.

## App gốc dùng gì (kết quả phân tích APK)

| Thành phần | App gốc (SlagClient) | Bản dựng lại |
|---|---|---|
| UI framework | Flutter (Dart, Kotlin Gradle 2.2.20) | Flutter |
| Core VPN | `libomnxt.so` — core dựa **sing-box** (VLESS/VMess/Trojan/SS) | `flutter_v2ray` (xray-core), cùng tập giao thức |
| Backend | **v2board/Xboard** (`/api/v1/passport/...`, `/api/v1/user/...`) | y hệt, xem `api_endpoints.dart` |
| Push | Firebase Messaging | (tuỳ chọn, chưa nhúng) |
| CSKH | Crisp chat | thay bằng nút "Customer Service" |
| Cờ quốc gia | `country_flags` | `country_flags` |
| Biểu đồ/Map | `flutter_map` | `fl_chart` cho Statistics |

App gốc còn fetch config qua các URL "bear.txt" trên OSS/COS — đây là kỹ thuật
**remote config chống chặn GFW** (đặt domain panel ở file txt trên CDN để đổi nhanh
khi bị chặn). Bạn đã làm tương tự với Cloudflare Worker, có thể tái dùng.

## Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry + MultiProvider + cổng login/main
├── core/
│   ├── api/
│   │   ├── api_endpoints.dart    # Mọi endpoint v2board (trích từ APK)
│   │   ├── api_client.dart       # Dio + tự gắn token + bóc {data:...}
│   │   └── v2board_service.dart  # Hàm nghiệp vụ: login, server, plan, invite...
│   ├── models/                   # UserInfo, ServerNode, Plan, InviteInfo
│   ├── vpn/vpn_service.dart      # Bọc flutter_v2ray, build share-link từ node v2board
│   └── storage/auth_storage.dart # Lưu token + subscribe url
├── providers/                    # auth / server / vpn (ChangeNotifier)
├── screens/
│   ├── login/                    # Đăng nhập + đăng ký (email code + invite)
│   ├── home/                     # Nút connect lớn + chọn node + danh sách node
│   ├── invite/                   # Mời bạn: QR + mã + hoa hồng
│   ├── statistics/               # Trạng thái VPN + biểu đồ 7 ngày
│   ├── profile/                  # Tài khoản + lưu lượng + menu
│   └── purchase/                 # Danh sách gói + mua
└── theme/app_theme.dart          # Theme tối
```

## Cách chạy

```bash
flutter pub get
# Sửa domain panel trước khi chạy:
#   lib/core/api/api_endpoints.dart  ->  static const baseUrl = 'https://vpnstore.pro.vn';
flutter run
```

## Cần chỉnh cho Android (flutter_v2ray)

1. `android/app/src/main/AndroidManifest.xml` — thêm trong `<application>`:
```xml
<service
    android:name="com.github.blueboytm.flutter_v2ray.service.V2rayVPNService"
    android:permission="android.permission.BIND_VPN_SERVICE"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <intent-filter>
        <action android:name="android.net.VpnService"/>
    </intent-filter>
</service>
```
và quyền:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
2. `minSdkVersion 24` trong `android/app/build.gradle` (giống app gốc).

## Mapping endpoint v2board → màn hình

- Login: `POST /api/v1/passport/auth/login` → trả `auth_data` (token header)
- Đăng ký: `POST /api/v1/passport/auth/register` (+ `email_code`, `invite_code`)
- Gửi mã: `POST /api/v1/passport/comm/sendEmailVerify`
- Thông tin user: `GET /api/v1/user/info` (balance, plan_id, expired_at, u/d, transfer_enable)
- Danh sách node: `GET /api/v1/user/server/fetch`
- Link subscribe: `GET /api/v1/user/getSubscribe`
- Gói cước: `GET /api/v1/user/plan/fetch`
- Tạo đơn: `POST /api/v1/user/order/save` → checkout `/order/checkout`
- Mời bạn: `GET /api/v1/user/invite/fetch` / `/invite/save`
- Redeem: `POST /api/v1/user/gift-card/redeem`

## Phần để bạn nối tiếp (TODO)

- **Thanh toán**: sau `createOrder` gọi `getPaymentMethods()` rồi `checkout()` để mở
  URL cổng thanh toán (mở bằng `url_launcher` hoặc `flutter_inappwebview`).
- **Statistics thật**: hiện biểu đồ 7 ngày đang dùng dữ liệu mẫu — nối log lưu lượng
  cục bộ hoặc API `/user/stat`.
- **Device management / Ticket / Redeem**: endpoint đã có sẵn trong service, chỉ cần
  thêm màn hình.
- **Đổi core sang sing-box** (giống `libomnxt`) nếu bạn muốn nạp trực tiếp link
  subscribe thay vì build từng node — dùng plugin sing-box thay `flutter_v2ray`.

> Lưu ý: app này nhắm tới chính panel v2board mà bạn đang vận hành. Chỉ kết nối tới
> hạ tầng của bạn, không phá vỡ DRM hay can thiệp dịch vụ của bên khác.
