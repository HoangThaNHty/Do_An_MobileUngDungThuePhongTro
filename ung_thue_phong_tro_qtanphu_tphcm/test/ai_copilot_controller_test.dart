import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/ai_copilot_controller.dart';

void main() {
  group('AICopilot Controller & Message Unit Tests', () {
    test('1. AICopilotMessage Initialization and Properties', () {
      final now = DateTime.now();
      final message = AICopilotMessage(
        role: 'user',
        text: 'Tìm phòng trọ Lũy Bán Bích',
        suggestedRoomIds: ['room_001', 'room_002'],
        rawJson: '{"text": "Mô tả", "suggested_room_ids": ["room_001", "room_002"]}',
        timestamp: now,
      );

      expect(message.role, 'user');
      expect(message.text, 'Tìm phòng trọ Lũy Bán Bích');
      expect(message.suggestedRoomIds, contains('room_001'));
      expect(message.suggestedRoomIds.length, 2);
      expect(message.rawJson, contains('room_001'));
      expect(message.timestamp, now);
    });

    test('2. Gemini Mock Response JSON Parsing Simulation', () {
      // Giả lập chuỗi JSON phản hồi có định dạng cấu trúc mà chúng ta yêu cầu Gemini trả về
      const mockGeminiJson = '''
      {
        "text": "Dưới đây là một số phòng trọ phù hợp với tiêu chí của bạn tại Lũy Bán Bích. Các phòng này đều có điều hòa và ban công thoáng mát.",
        "suggested_room_ids": ["room_tanphu_001", "room_tanphu_003"]
      }
      ''';

      // Thực hiện parse thử nghiệm
      final Map<String, dynamic> parsed = jsonDecode(mockGeminiJson);
      final replyText = parsed['text'] as String;
      final List<dynamic> suggestedIds = parsed['suggested_room_ids'] as List<dynamic>;

      expect(replyText, contains('Lũy Bán Bích'));
      expect(suggestedIds.length, 2);
      expect(suggestedIds, contains('room_tanphu_001'));
      expect(suggestedIds, contains('room_tanphu_003'));
    });
  });
}
