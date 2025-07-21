// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '操作乐趣铁路道口';

  @override
  String get thisApp => '这个应用程序是一个非常逼真的铁路道口模拟器。';

  @override
  String get confirmed => 'OK';

  @override
  String get back => '返回';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String passes(Object number) {
    return '铁路拍摄券: $number张';
  }

  @override
  String number(Object number) {
    return '$number张';
  }

  @override
  String shots(Object number) {
    return '剩余$number张';
  }

  @override
  String get noPasses => '无拍摄券';

  @override
  String get oneFreePerDay => '每日一张';

  @override
  String get album => '相册';

  @override
  String get worldsFirstApp => '获取由最先端生成式AI技术打造的专属于你的铁路照片！';

  @override
  String get current => '当前计划';

  @override
  String get plan => '计划';

  @override
  String get premium => '每月高级';

  @override
  String get standard => '每月标准';

  @override
  String get trial => '试用';

  @override
  String get free => '免费版';

  @override
  String get premiumTitle => '每月高级';

  @override
  String get standardTitle => '每月标准';

  @override
  String get price => '价格';

  @override
  String get ticket => '铁路拍摄券';

  @override
  String get tickets => '拍摄券';

  @override
  String get ticketNumber => '拍摄券数量';

  @override
  String get none => '无';

  @override
  String get todayPass => '今日的拍摄券';

  @override
  String get oneFree => '今日一张';

  @override
  String get timing => '发放与计费时间';

  @override
  String get renewal => '每月更新';

  @override
  String get immediate => '即时';

  @override
  String get rollover => '票据结转';

  @override
  String get rolloverTickets => '票据结转';

  @override
  String get available => '有';

  @override
  String get expire => '不结转';

  @override
  String get normally => 'Normally ';

  @override
  String get adFree => '无广告版';

  @override
  String get adDisplay => '广告显示';

  @override
  String adFreeDate(Object date) {
    return '无广告：$date前';
  }

  @override
  String freeDate(Object date) {
    return ' ($date前)';
  }

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get monthly => '/月';

  @override
  String get checkNetwork => '请检查您的网络连接。';

  @override
  String useTickets(Object number) {
    return '请将票数用到$number张以下。';
  }

  @override
  String photos(Object number) {
    return '$number张';
  }

  @override
  String get photoSaved => '照片已保存';

  @override
  String get photoCaptureFailed => '摄影失败';

  @override
  String get photoSavingFailed => '照片保存失败';

  @override
  String get photoAccessPermission => '为了保存火车图片，请在设置中允许对照片的完全访问。';

  @override
  String get buy => '购买';

  @override
  String get toBuy => '购买';

  @override
  String get toUpgrade => '升级';

  @override
  String get cancelSubscription => '取消付费计划';

  @override
  String get buyPasses => '购买拍摄券';

  @override
  String get upgrade => '升级';

  @override
  String get buyOnetimePasses => '购买追加拍摄券';

  @override
  String get onetime => '追加拍摄券';

  @override
  String nextRenewal(Object date) {
    return '更新日期: $date';
  }

  @override
  String get cancelPlan => '取消计划，请点此。';

  @override
  String get toRestore => '订阅计划的恢复';

  @override
  String get toOnetimeRestore => '恢复';

  @override
  String get contactUs => '联系我们';

  @override
  String get contactUrl => 'https://nakajimamasao-appstudio.web.app/contact/';

  @override
  String get terms => '使用条款与隐私政策';

  @override
  String get termsUrl => 'https://nakajimamasao-appstudio.web.app/terms/';

  @override
  String get premiumPlan => '高级计划';

  @override
  String get standardPlan => '标准计划';

  @override
  String get addOnPlan => '追加拍摄券';

  @override
  String planPurchase(Object plan) {
    return '$plan购买';
  }

  @override
  String planRestore(Object plan) {
    return '$plan恢复';
  }

  @override
  String planCancel(Object plan) {
    return '$plan取消';
  }

  @override
  String successPurchase(Object plan) {
    return '\n$plan\n购买已成功。';
  }

  @override
  String successRestore(Object plan) {
    return '\n$plan\n恢复已成功。\n剩余的拍摄券无法恢复。';
  }

  @override
  String successCancel(Object date, Object plan) {
    return '\n$plan将在下一个。\n更新日$date取消。';
  }

  @override
  String get successOnetime => '\n试用拍摄券购买已成功。';

  @override
  String get successAddOn => '\n追加拍摄券购买已成功。';

  @override
  String get errorPurchase => '购买错误';

  @override
  String get errorRestore => '恢复错误';

  @override
  String get errorCancel => '取消错误';

  @override
  String get finishPurchase => '\n该商品已购买。';

  @override
  String get finishRestore => '\n已完成恢复。';

  @override
  String get finishCancel => '\n已完成取消。';

  @override
  String get failPurchase => '\n无法进行购买。';

  @override
  String get failRestore => '\n未找到以前的购买记录。';

  @override
  String get failCancel => '\n无法进行取消。';

  @override
  String get purchaseCancelledMessage => '已取消购买。';

  @override
  String get paymentPendingMessage => '支付正在等待中。\n请检查商店。';

  @override
  String get purchaseInvalidMessage => '支付正在等待的项目。\n请检查商店。';

  @override
  String get purchaseNotAllowedMessage => '无法购买。\n请检查您的支付方式。';

  @override
  String get networkErrorMessage => '请连接到互联网。';
}
