# Altare iOS

Một bản dựng lại (rebuild) của app Android **Altare** (`altare.console`, v1.0.2 build 3) sang **iOS native** bằng **SwiftUI**, nối vào cùng backend `https://hosting.altare.gg`.

App gốc là Kotlin + Jetpack Compose (chỉ chạy Android) nên **không thể chuyển thẳng APK → IPA**. Repo này viết lại giao diện và client cho iOS, giữ nguyên bố cục và icon.

## Cần gì để build
- Máy Mac + Xcode (để build local), **hoặc** dùng sẵn GitHub Actions trong repo này.
- [XcodeGen](https://github.com/yonyz/XcodeGen) sinh file `.xcodeproj` từ `project.yml` (CI tự cài).

## Build tự động ra IPA (GitHub Actions)
1. Tạo repo mới trên GitHub và push toàn bộ thư mục này lên nhánh `main`.
2. Workflow `.github/workflows/build-ipa.yml` chạy tự động (hoặc vào tab **Actions** → **Run workflow**).
3. Khi xong, tải **`Altare-unsigned-ipa`** trong phần *Artifacts* của lần chạy.

> IPA này **chưa ký (unsigned)**. Để cài lên iPhone bạn cần ký bằng tài khoản Apple Developer
> (ví dụ dùng [AltStore](https://altstore.io), [Sideloadly](https://sideloadly.io), hoặc
> `codesign` với chứng chỉ + provisioning profile). App Store bắt buộc ký + provisioning riêng.

## Build local trên Mac
```bash
brew install xcodegen
xcodegen generate
open Altare.xcodeproj
```
Chọn team ký trong Signing & Capabilities rồi Run.

## Cấu trúc
```
Sources/          Mã Swift (App, Networking, Models, Session, các màn hình)
Resources/        Assets.xcassets (AppIcon lấy từ APK gốc, Logo, AccentColor)
project.yml       Cấu hình XcodeGen
.github/workflows Build IPA tự động
```

## Màn hình (bám theo app gốc)
- **Login** — logo "S", email/username + password, Sign in.
- **Servers** — danh sách server (RAM/Disk/CPU, badge trạng thái), nút +, chọn tenant.
- **Server detail** — Start/Restart/Stop/Kill, CPU/Memory/Uptime, tab Console/Files/Backups/Startup, gửi lệnh.
- **Wallet** — số dư credits, mua Memory/Disk/CPU/Server slots, ước tính chi phí.
- **Rewards** — daily reward + claim, AFK rewards, mã referral.
- **Account** — hồ sơ, tài nguyên đã dùng, sửa email/username.

## API đã reverse-engineer từ APK
Base URL: `https://hosting.altare.gg` — auth bằng `Bearer <token>` từ `POST api/auth/login`.
Các endpoint chính: `api/user/me`, `api/tenants`, `api/tenants/{t}/servers`,
`api/core/control/servers/{id}/power|command`, `api/tenants/{t}/wallet`,
`api/tenants/{t}/store/prices|purchase`, `api/tenants/{t}/rewards`, ...

## Lưu ý (đọc kỹ)
Vì mình dựng lại **không có source gốc**, một số điểm cần bạn kiểm/tinh chỉnh sau khi chạy thật:
- **Tên trường JSON trong response** (ví dụ cấu trúc `wallet`, `rewards`, `resources`) được suy đoán từ chuỗi trong APK. Nếu chỗ nào hiện `—` hoặc trống, mở DevTools/log của web `hosting.altare.gg` để lấy đúng key rồi sửa trong `Sources/Models.swift`.
- **Đăng nhập có thể yêu cầu captcha** (`capToken`). App gốc có bước captcha; ở đây gửi `capToken = nil`. Nếu server bắt buộc captcha, cần bổ sung luồng đó.
- **Console realtime** dùng WebSocket (vd `id-xxx.altare.gg:port`) — protocol này chưa reverse-engineer, nên tab Console hiện gửi lệnh + echo cục bộ, chưa stream log trực tiếp.
- Đơn vị RAM/Disk giả định là **MB** khi hiển thị sang GB.
