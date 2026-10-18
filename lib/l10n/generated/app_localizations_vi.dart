// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'LeafScan';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Huỷ';

  @override
  String get delete => 'Xoá';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get continueAction => 'Tiếp tục';

  @override
  String get consentTitle => 'Trước khi bắt đầu';

  @override
  String get consentIntro =>
      'Bạn hãy đọc và đồng ý với cách LeafScan dùng ảnh của bạn.';

  @override
  String get consentUploadTitle => 'Ảnh được gửi lên máy chủ';

  @override
  String get consentUploadBody =>
      'Mọi ảnh bạn chụp hoặc chọn đều được gửi lên máy chủ của chúng tôi.';

  @override
  String get consentTrainTitle => 'Dùng để huấn luyện AI';

  @override
  String get consentTrainBody =>
      'Ảnh và nhãn của ảnh được dùng để huấn luyện và cải thiện các mô hình.';

  @override
  String get consentOnlineTitle => 'Gửi khi có mạng';

  @override
  String get consentOnlineBody =>
      'Ảnh và kết quả dự đoán được lưu trên điện thoại cho đến khi có mạng.';

  @override
  String get consentReadTerms => 'Đọc toàn bộ điều khoản';

  @override
  String get consentCheckbox =>
      'Tôi đồng ý cho gửi ảnh của mình lên máy chủ và dùng để huấn luyện AI.';

  @override
  String get consentAgree => 'Đồng ý và tiếp tục';

  @override
  String get consentCloseApp => 'Đóng ứng dụng';

  @override
  String get termsTitle => 'Điều khoản đầy đủ';

  @override
  String get termsBack => 'Quay lại trang đồng ý';

  @override
  String get termsUploadsHeading => 'Ứng dụng gửi những gì';

  @override
  String get termsUploadsBody =>
      'Ứng dụng gửi lên mọi ảnh bạn chụp hoặc chọn, kèm kết quả dự đoán của mô hình và một điểm số cho biết mô hình chắc chắn đến đâu.';

  @override
  String get termsWhyHeading => 'Vì sao ứng dụng gửi ảnh';

  @override
  String get termsWhyBody =>
      'Những ảnh này góp vào bộ dữ liệu huấn luyện cho mô hình tiếp theo. Ảnh chụp ngoài vườn có ích hơn ảnh chụp trong phòng thí nghiệm.';

  @override
  String get termsWhenHeading => 'Khi nào ứng dụng gửi ảnh';

  @override
  String get termsWhenBody =>
      'Ứng dụng lưu từng ảnh cùng kết quả dự đoán trên điện thoại và chỉ gửi đi khi bạn đã đăng nhập và điện thoại có mạng.';

  @override
  String get termsNotCollectedHeading => 'Ứng dụng không thu thập gì';

  @override
  String get termsNotCollectedBody =>
      'Ứng dụng không hỏi tên, địa chỉ email hay số điện thoại của bạn. Ứng dụng cũng không đọc danh bạ và không theo dõi vị trí của bạn.';

  @override
  String get termsRetentionHeading => 'Dữ liệu được giữ bao lâu';

  @override
  String get termsRetentionBody =>
      'Ảnh được giữ trong suốt thời gian dự án nghiên cứu. Nhóm nghiên cứu quản lý số ảnh này, không bán và không giao cho bên quảng cáo nào.';

  @override
  String get termsStopHeading => 'Cách dừng';

  @override
  String get termsStopBody =>
      'Muốn dừng, bạn chỉ cần đóng ứng dụng. Ứng dụng không gửi gì trước khi bạn đồng ý.';

  @override
  String get signInTitle => 'Đăng nhập LeafScan';

  @override
  String get signInBody =>
      'Đăng nhập bằng tài khoản Google để dùng các mô hình và gửi ảnh của bạn.';

  @override
  String get signInWithGoogle => 'Đăng nhập bằng Google';

  @override
  String get catalogTitle => 'Chọn mô hình AI';

  @override
  String get catalogIntro =>
      'Mỗi mô hình nhận diện một loại cây trồng. Bạn xem các nhãn của mô hình trước khi quét nhé.';

  @override
  String catalogDeleteTitle(String name) {
    return 'Xoá $name?';
  }

  @override
  String get catalogDeleteBody =>
      'Mô hình sẽ bị xoá khỏi điện thoại. Bạn có thể tải lại sau.';

  @override
  String get catalogEmptyTitle => 'Chưa có mô hình';

  @override
  String get catalogEmptyBody =>
      'Chưa có loại cây trồng nào có mô hình được phát hành. Bạn quay lại sau nhé.';

  @override
  String catalogUseModel(String name) {
    return 'Dùng mô hình $name';
  }

  @override
  String get catalogChooseModel => 'Chọn một mô hình';

  @override
  String get catalogDownloadToStart => 'Tải một mô hình để bắt đầu';

  @override
  String get modelNotDownloaded => 'Chưa tải';

  @override
  String modelLabelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nhãn',
    );
    return '$_temp0';
  }

  @override
  String get modelDownloading => 'Đang tải…';

  @override
  String modelDownloadingPercent(int percent) {
    return 'Đang tải $percent%';
  }

  @override
  String get modelDownload => 'Tải về';

  @override
  String modelUpdateTo(String version) {
    return 'Cập nhật lên v$version';
  }

  @override
  String get captureTitle => 'Quét mới';

  @override
  String get captureBack => 'Quay lại danh sách mô hình';

  @override
  String get captureTakePhoto => 'Chụp ảnh';

  @override
  String get captureChooseFromLibrary => 'Chọn từ thư viện';

  @override
  String get captureRunning => 'Mô hình đang phân tích ảnh.';

  @override
  String get captureHeading => 'Thêm ảnh của một chiếc lá';

  @override
  String get captureHint =>
      'Chụp dưới ánh sáng ban ngày, trên nền trơn. Để chiếc lá chiếm gần hết khung hình.';

  @override
  String get resultTitle => 'Kết quả';

  @override
  String get resultPredictedLabel => 'Nhãn dự đoán';

  @override
  String resultModelLine(String name, String version) {
    return 'Mô hình $name · $version';
  }

  @override
  String get resultShowScores => 'Xem tất cả điểm số';

  @override
  String get resultHideScores => 'Ẩn điểm số';

  @override
  String get resultLatency => 'độ trễ';

  @override
  String get resultSignInToSend => 'Đăng nhập để gửi ảnh này';

  @override
  String get resultSent => 'Đã gửi ảnh. Cảm ơn bạn đã góp sức.';

  @override
  String resultPending(int count) {
    return 'Còn $count ảnh đang chờ. Ảnh sẽ được gửi khi điện thoại có mạng.';
  }

  @override
  String get failureSignInNotSetUp =>
      'Bản cài đặt này chưa thiết lập đăng nhập.';

  @override
  String get failureSignInCancelled => 'Bạn đã huỷ đăng nhập.';

  @override
  String get failureSignInUnfinished =>
      'Đăng nhập chưa hoàn tất. Vui lòng thử lại.';

  @override
  String get failureSignInRefused => 'Đăng nhập bị từ chối. Vui lòng thử lại.';

  @override
  String get failureSignInNeeded => 'Bạn cần đăng nhập để gửi ảnh.';

  @override
  String get failureSignInExpired =>
      'Phiên đăng nhập đã hết hạn. Bạn hãy đăng nhập lại để gửi ảnh.';

  @override
  String get failureCatalogOffline =>
      'Không có mạng. Bạn hãy kết nối internet để tải mô hình.';

  @override
  String get failureCatalogUnreadable =>
      'Ứng dụng không đọc được danh sách mô hình. Vui lòng thử lại.';

  @override
  String get failureModelNotReleased => 'Mô hình này chưa được phát hành.';

  @override
  String get failureDownloadDamaged => 'Tệp tải về bị lỗi. Vui lòng thử lại.';

  @override
  String get failureDownloadOffline => 'Mất mạng nên chưa tải xong.';

  @override
  String get failureDownloadFailed =>
      'Tải về không thành công. Vui lòng thử lại.';

  @override
  String get failurePhotoTooLarge => 'Ảnh lớn hơn 10 MB.';

  @override
  String get failureImageTooSmall =>
      'Ảnh quá nhỏ so với yêu cầu của mô hình này.';

  @override
  String get failureQuotaReached =>
      'Hôm nay bạn đã gửi đủ số ảnh cho phép. Những ảnh còn lại sẽ được gửi sau.';

  @override
  String get failureStorage =>
      'Điện thoại không lưu hoặc đọc được dữ liệu. Vui lòng thử lại.';

  @override
  String get failureModel => 'Mô hình không xử lý được ảnh này.';

  @override
  String get failureImage => 'Ứng dụng không đọc được ảnh này.';

  @override
  String get failurePermission =>
      'Hãy cho phép LeafScan dùng máy ảnh và thư viện ảnh trong phần Cài đặt.';

  @override
  String get failureAuth => 'Đăng nhập không thành công. Vui lòng thử lại.';

  @override
  String get failureNetwork =>
      'Không có mạng. Vui lòng thử lại khi điện thoại có mạng.';
}
