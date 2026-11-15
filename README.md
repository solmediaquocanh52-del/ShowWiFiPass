# ShowWiFiPass
Nút con mắt hiện/ẩn mật khẩu ở ô nhập Wi-Fi (iOS 15/16). Có mục cấu hình trong Cài đặt.

## Build (Theos)
    make package FINALPACKAGE=1                                  # rootful  -> iphoneos-arm
    make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless    # rootless -> iphoneos-arm64
    make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide    # roothide -> iphoneos-arm64e (cần fork roothide/theos)

Hoặc đẩy lên GitHub và chạy tab Actions -> tải artifact "debs".

## Debug nếu không thấy nút con mắt
Bật "Ghi log debug" trong cài đặt tweak, mở ô nhập pass Wi-Fi, xem log bằng Console/oslog
(lọc "ShowWiFiPass") để biết chuỗi class của ô mật khẩu, rồi chỉnh classLooksWiFi() trong Tweak.x.
Tạm thời có thể bật "Áp dụng mọi ô mật khẩu trong Cài đặt".
