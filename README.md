# Dream Tycoon — Game Roblox Tycoon

Game Tycoon hoàn chỉnh cho Roblox, code 100% bằng Luau và đồng bộ bằng **Rojo**.
Toàn bộ map (4 khu đất, băng chuyền, dropper, máy thu tiền) được **dựng bằng code khi server chạy** — bạn chỉ cần một place trống trong Roblox Studio.

## Gameplay

1. Vào game → tự động nhận 1 khu tycoon, được dịch chuyển tới khu của mình.
2. Dropper thả hộp hàng → băng chuyền đẩy tới máy thu → nhận **Cash**.
3. Dẫm lên nút xanh để mua vật phẩm theo thứ tự: Dropper 2 → Tường → Dropper 3 → Máy nâng cấp x2 → Dropper 4 → Trang trí → Dropper Vàng.
4. Cash và vật phẩm đã mua được **lưu tự động** bằng DataStore (lưu khi thoát + autosave 2 phút).

## Kiếm tiền (Robux) trong game này

| Tính năng | Trạng thái | Cách bật |
|---|---|---|
| Game Pass **x2 Cash** | Code xong, chờ ID | Creator Hub → game của bạn → Monetization → Passes → tạo pass, điền ID vào `Config.DoubleCashGamePassId` |
| Developer Product **mua Cash** | Code xong, chờ ID | Creator Hub → Monetization → Developer Products → tạo product, thêm vào `Config.CashProducts` dạng `[ProductId] = số Cash` |
| Creator Rewards | Tự có khi publish | Người chơi ở lại càng lâu, bạn càng được thưởng Robux |

Đổi Robux ra tiền thật qua **DevEx**: tối thiểu 30.000 Earned Robux, tỉ giá $0,0038/Robux.

## Cài đặt & chạy (Windows)

### 1. Cài Roblox Studio
Tải tại https://create.roblox.com — đăng nhập, tạo một **Experience** mới từ template **Baseplate**.

### 2. Cài Rojo
- Cài Rojo plugin trong Studio: mở Studio → Plugins → tìm "Rojo" → Install (hoặc cài từ Creator Store).
- Cài Rojo CLI trên máy (để chạy lệnh `rojo serve`): tải tại https://rojo.space (bản Windows), hoặc nếu đã có Rokit/Aftman thì `rokit add rojo-rbx/rojo`.

### 3. Lấy code & đồng bộ
```bat
git clone <link-repo-nay>
cd roblox-tycoon
rojo serve
```
Trong Studio: tab Plugins → Rojo → **Connect** → toàn bộ script sẽ chảy vào đúng vị trí (ReplicatedStorage, ServerScriptService, StarterPlayerScripts).

### 4. Bấm Play ▶ trong Studio
Map tycoon tự hiện ra. Đi lại, chờ dropper thả hàng, dẫm nút xanh để mua đồ.

## Muốn lưu DataStore chạy được trong Studio
Creator Hub → game của bạn → **Game Settings → Security → Enable Studio Access to API Services** = On. Không bật thì code vẫn chạy, chỉ là dữ liệu không lưu thật khi test trong Studio (code đã có pcall bảo vệ).

## Publish game để người khác chơi
Studio → File → **Publish to Roblox** → đặt tên, mô tả → Create. Sau đó vào Creator Hub đặt game ở chế độ **Public**.

## Cấu trúc code

```
default.project.json     # bản đồ Rojo: thư mục nào vào service nào
src/
  shared/Config.lua      # MỌI số liệu game: giá đồ, tốc độ drop, ID bán hàng
  server/
    Main.server.lua      # khởi chạy, nối người chơi vào hệ thống, autosave
    TycoonManager.lua    # dựng map, dropper, băng chuyền, nút mua, thu tiền
    DataManager.lua      # lưu/tải DataStore
    Monetization.lua     # Game Pass x2 + Developer Product (ProcessReceipt)
  client/
    HUD.client.lua       # HUD tiền, thông báo, nút mua Robux
```

## Chỉnh game theo ý bạn
Mở `src/shared/Config.lua`: đổi giá/tốc độ trong `Config.Items`, số khu đất ở `Config.PlotCount`, tiền khởi đầu ở `Config.StartingCash`. Lưu file → Rojo tự đồng bộ vào Studio.

## Lộ trình v2
- Rebirth (tái sinh nhận hệ số nhân vĩnh viễn)
- Bảng xếp hạng Cash toàn server
- Thú cưng / hiệu ứng cho người mua VIP
- Khu đất thứ 2, nâng cấp dropper bằng Robux
