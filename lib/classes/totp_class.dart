class TotpClass {
  final int? id;
  final String issuer;
  final String secret; //Base32 string
  final String label;
  final int digits;
  int period;

  TotpClass(
      {this.id, required this.issuer, required this.secret, required this.label, required this.digits, this.period = 30});

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'issuer': issuer,
      'secret': secret,
      'label': label,
      'digits': digits,
      'period': period
    };
  }

  @override
  String toString() {
    return "Totp(id: $id)";
  }

}