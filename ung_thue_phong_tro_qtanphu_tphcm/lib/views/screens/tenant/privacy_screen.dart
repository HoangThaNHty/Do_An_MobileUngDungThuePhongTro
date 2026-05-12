import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Chính sách & Điều khoản'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionCard(
            icon: Icons.policy_outlined,
            title: 'Điều khoản sử dụng',
            content:
                'Bằng cách sử dụng ứng dụng Phòng Trọ Tân Phú, bạn đồng ý tuân thủ các điều khoản và điều kiện được quy định trong tài liệu này. Chúng tôi có quyền thay đổi điều khoản bất kỳ lúc nào và sẽ thông báo trước 30 ngày.',
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            content:
                'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn. Dữ liệu thu thập chỉ được dùng để cung cấp dịch vụ và không được chia sẻ với bên thứ ba mà không có sự đồng ý của bạn. Tất cả dữ liệu được mã hóa theo chuẩn AES-256.',
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            icon: Icons.home_outlined,
            title: 'Chính sách thuê phòng',
            content:
                'Người thuê phải đặt cọc tương đương 1-2 tháng tiền thuê. Hợp đồng thuê tối thiểu 6 tháng. Thông báo trước 30 ngày khi muốn chấm dứt hợp đồng. Tiền điện tính theo giá quy định của nhà nước.',
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            icon: Icons.payment_outlined,
            title: 'Chính sách thanh toán',
            content:
                'Tiền thuê thanh toán vào ngày 1-5 hàng tháng. Quá hạn 10 ngày sẽ tính phí trễ 1%/ngày. Hóa đơn điện nước gửi trước ngày 10 hàng tháng. Chấp nhận thanh toán chuyển khoản ngân hàng.',
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            icon: Icons.security_outlined,
            title: 'Quy định an ninh',
            content:
                'Bảo vệ 24/7. Camera an ninh toàn khu. Không tiếp khách sau 22:00. Không nuôi thú cưng. Không sử dụng chất cấm. Vi phạm sẽ bị chấm dứt hợp đồng ngay lập tức.',
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            icon: Icons.support_agent_outlined,
            title: 'Hỗ trợ khách hàng',
            content:
                'Hotline: 1800-xxxx (miễn phí, 8:00-18:00 các ngày làm việc)\nEmail: support@phongtrotanphu.vn\nPhản hồi trong vòng 24 giờ làm việc.',
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Cập nhật lần cuối: 01/01/2024\nPhiên bản 1.0.0',
              style: AppTypography.bodySM,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: AppTypography.titleSM),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(content, style: AppTypography.bodyMD),
        ],
      ),
    );
  }
}
