import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/user.dart';
import 'auth_controller.dart';

// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
    );
  }
}

// Chat room model
class ChatRoom {
  final String id;
  final String tenantId;
  final String landlordId;
  final String tenantName;
  final String landlordName;
  final String? tenantAvatar;
  final String? landlordAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadByTenant;
  final int unreadByLandlord;

  const ChatRoom({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.tenantName,
    required this.landlordName,
    this.tenantAvatar,
    this.landlordAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadByTenant = 0,
    this.unreadByLandlord = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'tenantName': tenantName,
      'landlordName': landlordName,
      'tenantAvatar': tenantAvatar,
      'landlordAvatar': landlordAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadByTenant': unreadByTenant,
      'unreadByLandlord': unreadByLandlord,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      landlordName: map['landlordName'] ?? '',
      tenantAvatar: map['tenantAvatar'],
      landlordAvatar: map['landlordAvatar'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.tryParse(map['lastMessageTime']) ?? DateTime.now()
          : DateTime.now(),
      unreadByTenant: map['unreadByTenant'] ?? 0,
      unreadByLandlord: map['unreadByLandlord'] ?? 0,
    );
  }
}

// ChatController managing logic
class ChatController {
  FirebaseDatabase get _db => FirebaseDatabase.instance;

  ChatController();

  /// Lắng nghe các phòng chat của User hiện tại
  Stream<List<ChatRoom>> watchChats(String currentUserId) {
    final ref = _db.ref('chats');
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final chatRooms = <ChatRoom>[];

      data.forEach((key, value) {
        final chatData = Map<String, dynamic>.from(value as Map);
        final chatRoom = ChatRoom.fromMap(chatData);
        
        // Chỉ lấy cuộc trò chuyện liên quan đến User hiện tại
        if (chatRoom.tenantId == currentUserId || chatRoom.landlordId == currentUserId) {
          chatRooms.add(chatRoom);
        }
      });

      // Sắp xếp cuộc trò chuyện có tin nhắn mới nhất lên đầu
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chatRooms;
    });
  }

  /// Lắng nghe tin nhắn trong một phòng chat cụ thể
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final ref = _db.ref('chats/$chatId/messages');
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final messages = <ChatMessage>[];

      data.forEach((key, value) {
        final msgData = Map<String, dynamic>.from(value as Map);
        messages.add(ChatMessage.fromMap(msgData));
      });

      // Sắp xếp tin nhắn theo thời gian tăng dần để hiện từ cũ đến mới
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Tạo hoặc lấy phòng chat giữa Tenant và Landlord
  Future<String> getOrCreateChatRoom({
    required AppUser tenant,
    required AppUser landlord,
  }) async {
    final chatId = '${tenant.id}_${landlord.id}';
    final ref = _db.ref('chats/$chatId');
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      const welcomeText = 'Chào bạn! Cảm ơn bạn đã quan tâm đến phòng trọ của tôi. Bạn có cần tôi tư vấn thêm gì hay muốn hẹn lịch qua xem phòng thực tế không ạ?';
      
      final newRoom = ChatRoom(
        id: chatId,
        tenantId: tenant.id,
        landlordId: landlord.id,
        tenantName: tenant.fullName,
        landlordName: landlord.fullName,
        tenantAvatar: tenant.avatarUrl,
        landlordAvatar: landlord.avatarUrl,
        lastMessage: welcomeText,
        lastMessageTime: DateTime.now(),
        unreadByTenant: 1, // Đánh dấu 1 tin nhắn chưa đọc cho tenant thấy thông báo
        unreadByLandlord: 0,
      );

      await ref.set(newRoom.toMap());

      // Tự động chèn tin nhắn chào mừng từ phía chủ trọ (landlord) vào sub-node messages
      final msgRef = _db.ref('chats/$chatId/messages').push();
      final welcomeMsg = ChatMessage(
        id: msgRef.key!,
        senderId: landlord.id,
        text: welcomeText,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await msgRef.set(welcomeMsg.toMap());
    } else {
      // Cập nhật lại tên/avatar mới nhất đề phòng người dùng đổi
      await ref.update({
        'tenantName': tenant.fullName,
        'landlordName': landlord.fullName,
        'tenantAvatar': tenant.avatarUrl,
        'landlordAvatar': landlord.avatarUrl,
      });
    }

    return chatId;
  }

  /// Gửi tin nhắn
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required bool isSenderLandlord,
  }) async {
    if (text.trim().isEmpty) return;

    final msgRef = _db.ref('chats/$chatId/messages').push();
    final newMsg = ChatMessage(
      id: msgRef.key!,
      senderId: senderId,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    // 1. Lưu tin nhắn
    await msgRef.set(newMsg.toMap());

    // 2. Cập nhật phòng chat: tin nhắn cuối, thời gian, và số tin nhắn chưa đọc
    final roomRef = _db.ref('chats/$chatId');
    final snapshot = await roomRef.get();
    
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      int unreadTenant = data['unreadByTenant'] ?? 0;
      int unreadLandlord = data['unreadByLandlord'] ?? 0;

      if (isSenderLandlord) {
        unreadTenant += 1;
      } else {
        unreadLandlord += 1;
      }

      await roomRef.update({
        'lastMessage': text.trim(),
        'lastMessageTime': DateTime.now().toIso8601String(),
        'unreadByTenant': unreadTenant,
        'unreadByLandlord': unreadLandlord,
      });
    }
  }

  /// Đánh dấu là đã đọc toàn bộ tin nhắn trong phòng chat
  Future<void> markAsRead(String chatId, String currentUserId, bool isLandlord) async {
    final roomRef = _db.ref('chats/$chatId');
    
    if (isLandlord) {
      await roomRef.update({'unreadByLandlord': 0});
    } else {
      await roomRef.update({'unreadByTenant': 0});
    }
  }
}

// Providers
final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController();
});

// StreamProvider cho danh sách chats của user hiện tại
final myChatsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatControllerProvider).watchChats(user.id);
});

// StreamProvider cho tin nhắn trong chat room
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatControllerProvider).watchMessages(chatId);
});

// Provider tính tổng số tin nhắn chưa đọc realtime dựa vào role của người dùng hiện tại
final unreadChatsCountProvider = Provider<int>((ref) {
  final chatsAsync = ref.watch(myChatsProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  return chatsAsync.maybeWhen(
    data: (chats) {
      final isLandlord = user.role == UserRole.landlord;
      return chats.fold<int>(0, (sum, chat) {
        return sum + (isLandlord ? chat.unreadByLandlord : chat.unreadByTenant);
      });
    },
    orElse: () => 0,
  );
});
