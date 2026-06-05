import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/gemini_config.dart';
import '../models/entities/bill.dart';
import '../models/entities/rental.dart';
import '../models/entities/room.dart';
import 'ai_copilot_controller.dart';
import 'auth_controller.dart';
import 'providers/bill_provider.dart';
import 'providers/room_provider.dart';

class LandlordAICopilotNotifier extends StateNotifier<AICopilotState> {
  final Ref ref;

  LandlordAICopilotNotifier(this.ref)
      : super(AICopilotState(
          messages: [
            AICopilotMessage(
              role: 'model',
              text:
                  'Xin chào chủ trọ. Mình có thể hỗ trợ bạn xem nhanh phòng trống, phòng đang thuê, hóa đơn chờ duyệt, hóa đơn chưa thanh toán, doanh thu tháng này và gợi ý nội dung trao đổi với người thuê.',
              timestamp: DateTime.now(),
            )
          ],
        ));

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    final userMsg = AICopilotMessage(
      role: 'user',
      text: userMessage.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      if (_isGreetingOnly(userMessage)) {
        _appendModel(
          'Xin chào. Bạn có thể hỏi: "Phòng nào đang trống?", "Ai chưa thanh toán?", "Có hóa đơn nào chờ duyệt không?" hoặc "Doanh thu tháng này bao nhiêu?".',
        );
        return;
      }

      if (!_isInLandlordScope(userMessage)) {
        _appendModel(
          'Mình chỉ hỗ trợ các nội dung trong phạm vi quản lý phòng trọ của app: phòng, người thuê, hợp đồng, hóa đơn, thanh toán, doanh thu, chat với khách thuê và thao tác sử dụng app.',
        );
        return;
      }

      final snapshot = _buildSnapshot();
      final localReply = _tryLocalAnswer(userMessage, snapshot);
      if (localReply != null) {
        _appendModel(localReply);
        return;
      }

      final reply = await _askGemini(userMessage, snapshot);
      _appendModel(reply, rawJson: jsonEncode({'text': reply}));
    } catch (e) {
      final errorMsg = AICopilotMessage(
        role: 'model',
        text: _friendlyErrorMessage(e),
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  _LandlordSnapshot _buildSnapshot() {
    final user = ref.read(currentUserProvider);
    final rooms = ref
        .read(roomProvider)
        .rooms
        .where((room) => room.landlordId == user?.id)
        .toList();
    final roomIds = rooms.map((room) => room.id).toSet();

    final rentals = (ref.read(allRentalsProvider).valueOrNull ?? <Rental>[])
        .where((rental) => rental.landlordId == user?.id)
        .toList();
    final bills = (ref.read(allBillsProvider).valueOrNull ?? <Bill>[])
        .where((bill) => roomIds.contains(bill.roomId))
        .toList();

    return _LandlordSnapshot(
      rooms: rooms,
      rentals: rentals,
      bills: bills,
    );
  }

  String? _tryLocalAnswer(String message, _LandlordSnapshot snapshot) {
    final normalized = normalizeRoomSearchText(message);
    final pendingPayments = snapshot.pendingPaymentBills;
    final unpaidBills = snapshot.unpaidBills;
    final availableRooms = snapshot.availableRooms;
    final rentedRooms = snapshot.rentedRooms;

    if (_containsAny(
        normalized, ['cho duyet', 'cho xac nhan', 'da chuyen tien'])) {
      if (pendingPayments.isEmpty) {
        return 'Hiện chưa có hóa đơn nào khách đã báo chuyển tiền đang chờ chủ trọ duyệt.';
      }
      return 'Có ${pendingPayments.length} hóa đơn đang chờ duyệt:\n'
          '${pendingPayments.map((bill) => '- ${bill.tenantName} - ${bill.roomTitle}: ${_formatCurrency(bill.totalAmount)}đ').join('\n')}\n\nBạn vào màn Người thuê > Lịch sử hóa đơn để duyệt hoặc từ chối.';
    }

    if (_containsAny(normalized, ['chua thanh toan', 'no tien', 'chua tra'])) {
      if (unpaidBills.isEmpty) {
        return 'Hiện chưa có hóa đơn chưa thanh toán nào cần nhắc.';
      }
      return 'Có ${unpaidBills.length} hóa đơn chưa thanh toán:\n'
          '${unpaidBills.map((bill) => '- ${bill.tenantName} - ${bill.roomTitle}: ${_formatCurrency(bill.totalAmount)}đ, hạn ${_formatDate(bill.dueDate)}').join('\n')}';
    }

    if (_containsAny(normalized, ['phong trong', 'con trong', 'dang trong'])) {
      if (availableRooms.isEmpty) {
        return 'Hiện chưa có phòng nào ở trạng thái còn trống.';
      }
      return 'Bạn đang có ${availableRooms.length} phòng còn trống:\n'
          '${availableRooms.map((room) => '- ${room.title}: ${_formatCurrency(room.price)}đ/tháng, ${room.area.toStringAsFixed(0)} m²').join('\n')}';
    }

    if (_containsAny(normalized, ['dang thue', 'da thue', 'nguoi thue'])) {
      if (rentedRooms.isEmpty) {
        return 'Hiện chưa có phòng nào ở trạng thái đang thuê.';
      }
      return 'Bạn đang có ${rentedRooms.length} phòng đang thuê:\n'
          '${rentedRooms.map((room) => '- ${room.title}: ${_formatCurrency(room.price)}đ/tháng').join('\n')}';
    }

    if (_containsAny(normalized, ['doanh thu', 'thu nhap', 'tien thang nay'])) {
      return 'Doanh thu dự kiến theo tiền thuê phòng đang thuê là ${_formatCurrency(snapshot.monthlyRevenue)}đ/tháng.\n'
          'Hóa đơn đã thanh toán trong tháng này: ${_formatCurrency(snapshot.paidRevenueThisMonth)}đ.';
    }

    if (_containsAny(normalized, ['tao hoa don', 'lap hoa don'])) {
      return 'Mình có thể giúp bạn soạn nháp hóa đơn, nhưng không tự tạo hóa đơn vào Firebase. Bạn hãy vào tab Hóa đơn, chọn phòng đang thuê, nhập chỉ số điện/nước và bấm Tạo hóa đơn. App đã chặn tạo trùng hóa đơn tháng cho cùng người thuê.';
    }

    if (_containsAny(normalized, ['soan tin', 'tin nhan', 'nhac khach'])) {
      return 'Bạn có thể gửi khách thuê nội dung sau:\n\n'
          '"Chào bạn, mình là chủ trọ. Hiện hóa đơn tiền phòng tháng này của bạn vẫn chưa được xác nhận thanh toán trên hệ thống. Bạn vui lòng kiểm tra lại và phản hồi giúp mình khi đã chuyển khoản nhé. Cảm ơn bạn."';
    }

    return null;
  }

  Future<String> _askGemini(String message, _LandlordSnapshot snapshot) async {
    final roomContext = snapshot.rooms.map((room) {
      return '- ${room.title}: ${room.status.name}, ${_formatCurrency(room.price)}đ/tháng, ${room.area} m2, ${room.address}';
    }).join('\n');

    final rentalContext = snapshot.rentals.map((rental) {
      return '- ${rental.tenantName}: ${rental.roomTitle}, ${rental.status.name}, từ ${_formatDate(rental.startDate)} đến ${_formatDate(rental.endDate)}';
    }).join('\n');

    final billContext = snapshot.bills.map((bill) {
      return '- ${bill.tenantName}: ${bill.roomTitle}, ${bill.status.name}, paymentSubmitted=${bill.paymentSubmitted}, ${_formatCurrency(bill.totalAmount)}đ, hạn ${_formatDate(bill.dueDate)}';
    }).join('\n');

    final systemPrompt = '''
Bạn là "Landlord AI Copilot" trong ứng dụng thuê phòng trọ Quận Tân Phú.
Bạn hỗ trợ chủ trọ quản lý phòng, người thuê, hóa đơn, thanh toán, doanh thu và soạn tin nhắn cho khách thuê.

Dữ liệu hiện tại của chủ trọ:
PHÒNG:
$roomContext

HỢP ĐỒNG/NGƯỜI THUÊ:
$rentalContext

HÓA ĐƠN:
$billContext

Quy tắc:
1. Chỉ trả lời trong phạm vi app thuê phòng trọ và quản lý chủ trọ.
2. Không tự ý nói rằng đã tạo/sửa/xóa dữ liệu. Nếu cần thao tác ghi dữ liệu, hãy hướng dẫn chủ trọ vào màn tương ứng và bấm xác nhận.
3. Nếu câu hỏi ngoài phạm vi, từ chối ngắn gọn và kéo về nghiệp vụ app.
4. Trả lời tiếng Việt, ngắn gọn, rõ việc cần làm.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${GeminiConfig.modelName}:generateContent?key=${GeminiConfig.geminiApiKey}',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': message}
            ],
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
    if (text is String && text.trim().isNotEmpty) return text.trim();
    throw Exception('Gemini không trả về nội dung hợp lệ.');
  }

  bool _containsAny(String source, List<String> keywords) {
    return keywords.any(source.contains);
  }

  bool _isGreetingOnly(String message) {
    final normalized = normalizeRoomSearchText(message);
    return {'hi', 'hello', 'xin chao', 'chao', 'alo'}.contains(normalized);
  }

  bool _isInLandlordScope(String message) {
    final normalized = normalizeRoomSearchText(message);
    const keywords = [
      'phong',
      'tro',
      'thue',
      'chu tro',
      'nguoi thue',
      'khach',
      'hop dong',
      'hoa don',
      'thanh toan',
      'vietqr',
      'doanh thu',
      'tien',
      'coc',
      'duyet',
      'tu choi',
      'chat',
      'tin nhan',
      'goi',
      'dia chi',
      'tan phu',
      'app',
      'tai khoan',
      'phong trong',
      'dang thue',
      'tao hoa don',
      'lap hoa don',
      'nhac',
    ];
    return keywords.any(normalized.contains);
  }

  String _friendlyErrorMessage(Object error) {
    final detail = error.toString();
    if (detail.contains('404') || detail.contains('NOT_FOUND')) {
      return 'Mình chưa kết nối được mô hình AI đang cấu hình. Vui lòng kiểm tra GEMINI_API_KEY/model trong cấu hình.';
    }
    if (detail.contains('403') || detail.contains('API_KEY_INVALID')) {
      return 'API key Gemini chưa hợp lệ hoặc chưa có quyền sử dụng.';
    }
    if (detail.contains('429') || detail.contains('RESOURCE_EXHAUSTED')) {
      return 'Hệ thống AI đang vượt hạn mức gọi API. Bạn thử lại sau ít phút.';
    }
    return 'Mình gặp lỗi kết nối AI. Các câu hỏi thống kê nhanh như phòng trống, hóa đơn chờ duyệt vẫn có thể xử lý nội bộ.';
  }

  void _appendModel(String text, {String? rawJson}) {
    final modelMsg = AICopilotMessage(
      role: 'model',
      text: text,
      rawJson: rawJson,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, modelMsg],
      isLoading: false,
    );
  }

  void clearHistory() {
    state = AICopilotState(
      messages: [
        AICopilotMessage(
          role: 'model',
          text:
              'Hội thoại đã được làm mới. Bạn có thể hỏi nhanh về phòng trống, hóa đơn chờ duyệt, người thuê hoặc doanh thu.',
          timestamp: DateTime.now(),
        )
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _LandlordSnapshot {
  final List<Room> rooms;
  final List<Rental> rentals;
  final List<Bill> bills;

  const _LandlordSnapshot({
    required this.rooms,
    required this.rentals,
    required this.bills,
  });

  List<Room> get availableRooms =>
      rooms.where((room) => room.status == RoomStatus.available).toList();

  List<Room> get rentedRooms =>
      rooms.where((room) => room.status == RoomStatus.rented).toList();

  List<Bill> get pendingPaymentBills => bills
      .where(
          (bill) => bill.status == BillStatus.unpaid && bill.paymentSubmitted)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Bill> get unpaidBills => bills
      .where(
          (bill) => bill.status == BillStatus.unpaid && !bill.paymentSubmitted)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  int get monthlyRevenue =>
      rentedRooms.fold(0, (sum, room) => sum + room.price);

  int get paidRevenueThisMonth {
    final now = DateTime.now();
    return bills
        .where((bill) =>
            bill.status == BillStatus.paid &&
            bill.billingMonth.month == now.month &&
            bill.billingMonth.year == now.year)
        .fold(0, (sum, bill) => sum + bill.totalAmount);
  }
}

final landlordAICopilotProvider =
    StateNotifierProvider<LandlordAICopilotNotifier, AICopilotState>((ref) {
  return LandlordAICopilotNotifier(ref);
});
