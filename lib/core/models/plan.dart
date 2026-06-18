/// Gói cước từ /api/v1/user/plan/fetch.
class Plan {
  final int id;
  final String name;
  final String? content;
  final num? monthPrice;
  final num? quarterPrice;
  final num? halfYearPrice;
  final num? yearPrice;
  final num? onetimePrice;
  final int? transferEnable; // GB
  final int? deviceLimit;

  Plan({
    required this.id,
    required this.name,
    this.content,
    this.monthPrice,
    this.quarterPrice,
    this.halfYearPrice,
    this.yearPrice,
    this.onetimePrice,
    this.transferEnable,
    this.deviceLimit,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] ?? 0,
        name: j['name']?.toString() ?? '',
        content: j['content']?.toString(),
        monthPrice: j['month_price'],
        quarterPrice: j['quarter_price'],
        halfYearPrice: j['half_year_price'],
        yearPrice: j['year_price'],
        onetimePrice: j['onetime_price'],
        transferEnable: j['transfer_enable'],
        deviceLimit: j['device_limit'],
      );

  /// Danh sách (period, giá xu) khả dụng.
  List<MapEntry<String, num>> get periods {
    final out = <MapEntry<String, num>>[];
    void add(String k, num? v) {
      if (v != null && v > 0) out.add(MapEntry(k, v));
    }
    add('month_price', monthPrice);
    add('quarter_price', quarterPrice);
    add('half_year_price', halfYearPrice);
    add('year_price', yearPrice);
    add('onetime_price', onetimePrice);
    return out;
  }
}
