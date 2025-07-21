// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'レッツ・カンカン';

  @override
  String get thisApp => 'このアプリはとてもリアルな踏切シミュレーターです。';

  @override
  String get confirmed => '確認';

  @override
  String get back => '戻る';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String passes(Object number) {
    return '撮り鉄チケット: $number枚';
  }

  @override
  String number(Object number) {
    return '$number枚';
  }

  @override
  String shots(Object number) {
    return '残り$number枚';
  }

  @override
  String get noPasses => '残数なし';

  @override
  String get oneFreePerDay => '本日1回';

  @override
  String get album => 'アルバム';

  @override
  String get worldsFirstApp => '話題の生成AI技術で、あなただけの撮り鉄写真を手に入れよう！';

  @override
  String get current => '現在の\nプラン';

  @override
  String get plan => 'プラン';

  @override
  String get premium => 'プレミアム月額';

  @override
  String get standard => 'スタンダード月額';

  @override
  String get trial => 'お試し';

  @override
  String get free => 'フリー';

  @override
  String get premiumTitle => 'プレミアム\n月額';

  @override
  String get standardTitle => 'スタンダード\n月額';

  @override
  String get price => '価格';

  @override
  String get ticket => '撮り鉄チケット';

  @override
  String get tickets => '撮り鉄\nチケット';

  @override
  String get ticketNumber => 'チケット枚数';

  @override
  String get none => 'なし';

  @override
  String get todayPass => '本日のチケット';

  @override
  String get oneFree => '本日1回';

  @override
  String get timing => '付与・請求\nタイミング';

  @override
  String get renewal => '毎月更新';

  @override
  String get immediate => '即時';

  @override
  String get rollover => 'チケット\n繰越';

  @override
  String get rolloverTickets => 'チケット繰越';

  @override
  String get available => '繰越あり';

  @override
  String get expire => '繰越なし';

  @override
  String get normally => '通常';

  @override
  String get adFree => '広告なし';

  @override
  String get adDisplay => '広告表示';

  @override
  String adFreeDate(Object date) {
    return '広告なし：$dateまで';
  }

  @override
  String freeDate(Object date) {
    return ' (~$date)';
  }

  @override
  String get yes => 'あり';

  @override
  String get no => 'なし';

  @override
  String get monthly => '/月';

  @override
  String get checkNetwork => 'ネットワークの状態を確認してください。';

  @override
  String useTickets(Object number) {
    return 'チケットを$number回以下まで使用して下さい。';
  }

  @override
  String photos(Object number) {
    return '$number回';
  }

  @override
  String get photoSaved => '写真を保存しました';

  @override
  String get photoCaptureFailed => '撮影に失敗しました';

  @override
  String get photoSavingFailed => '写真が保存に失敗しました';

  @override
  String get photoAccessPermission => '電車の画像を保存するため、設定画面で写真へのフルアクセスを許可してください。';

  @override
  String get buy => '購入';

  @override
  String get toBuy => '購入する';

  @override
  String get toUpgrade => 'アップグレードする';

  @override
  String get cancelSubscription => '有料プランの解約';

  @override
  String get buyPasses => 'チケットの購入';

  @override
  String get upgrade => 'アップグレード';

  @override
  String get buyOnetimePasses => '追加チケットの購入';

  @override
  String get onetime => '追加チケット';

  @override
  String nextRenewal(Object date) {
    return '次回更新日: $date';
  }

  @override
  String get cancelPlan => '解約はこちら';

  @override
  String get toRestore => 'サブスクリプションプランの復元';

  @override
  String get toOnetimeRestore => '復元';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get contactUrl =>
      'https://nakajimamasao-appstudio.web.app/contact/ja/';

  @override
  String get terms => '利用規約・プライバシーポリシー';

  @override
  String get termsUrl => 'https://nakajimamasao-appstudio.web.app/terms/ja/';

  @override
  String get premiumPlan => 'プレミアムプラン';

  @override
  String get standardPlan => 'スタンダードプラン';

  @override
  String get addOnPlan => '追加チケット';

  @override
  String planPurchase(Object plan) {
    return '$planの\n購入';
  }

  @override
  String planRestore(Object plan) {
    return '$planの\n復元';
  }

  @override
  String planCancel(Object plan) {
    return '$planの\n解約';
  }

  @override
  String successPurchase(Object plan) {
    return '\n$planの\n購入が完了しました。';
  }

  @override
  String successRestore(Object plan) {
    return '\n$planの\n復元が完了しました。\n撮影チケットの残数は復元できません。';
  }

  @override
  String successCancel(Object date, Object plan) {
    return '\n次の更新日$dateに\n$planは解約されます。';
  }

  @override
  String get successOnetime => '\nお試しチケットの\n購入が完了しました。';

  @override
  String get successAddOn => '\n追加チケットの\n購入が完了しました。';

  @override
  String get errorPurchase => '購入エラー';

  @override
  String get errorRestore => '復元エラー';

  @override
  String get errorCancel => '解約エラー';

  @override
  String get finishPurchase => '\nこの商品は購入済です。';

  @override
  String get finishRestore => '\n復元は完了しています。';

  @override
  String get finishCancel => '\nキャンセルは完了しています。';

  @override
  String get failPurchase => '\n購入できませんでした。';

  @override
  String get failRestore => '\n過去の購入履歴が\n見つかりませんでした。';

  @override
  String get failCancel => '\n解約できませんでした。';

  @override
  String get purchaseCancelledMessage => '\n購入をキャンセルしました。';

  @override
  String get paymentPendingMessage => '\nお支払いが保留中です。\nストアをご確認ください。';

  @override
  String get purchaseInvalidMessage => '\nお支払いが保留中の商品です。\nストアをご確認ください。';

  @override
  String get purchaseNotAllowedMessage => '\n購入できませんでした。\nお支払い方法をご確認ください。';

  @override
  String get networkErrorMessage => '\nインターネットに接続してください。';
}
