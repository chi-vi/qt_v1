# qt_v1

Code của máy dịch cũ Chivi

## Cài đặt

Vào Discord hỏi.

## Cách dùng

### Dịch nhanh:

Gọi POST request tới `http://localhost:6666/qtran` với body của request là text muốn dịch.

_Lưu ý: Cần thêm header "Content-Type: text/plain" khi gọi request._

Các lựa chọn:

####: Dùng từ điển bộ truyện:
thêm param `wn_id=?` vào địa chỉ, ví dụ `http://localhost:6666/qtran?wn_id=666`

####: Dịch đặc biệt tên chương:
thêm param `title=1` vào địa chỉ, ví dụ: `http://localhost:6666/qtran?wn_id=666&title=1`

có thể thay vào bằng `title=2` nếu muốn tất cả các dòng đều áp dụng cách dịch tên chương.

### Thêm từ mới:

Gọi POST request tới `http://localhost:6666/terms`, body là một JSON với format:

_Lưu ý: Cần thêm header "Content-Type: application/json" khi gọi request._

```
{
  key: string
  val: string
  ptag: string
  prio: number
  dic: number
  tab: number
}
```

trong đó:

- key: text tiếng trung gốc
- val: nghĩa tiếng việt
- ptag: từ loại của nghĩa
- prio: mức độ ưu tiên của từ trong câu (tốt nhất để mặc định)
- dic: id từ điển, trong đó: -1 là từ điển chung cho tất cả bộ truyện, 0 là từ điển dịch nhanh, 1+ là từ điển bộ truyện
- tab: (cần xóa) lưu vào từ điển tạm thời hoặc chính thức, dùng cho hệ thống cũ
