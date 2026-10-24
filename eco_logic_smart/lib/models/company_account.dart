class CompanyAccount {
  const CompanyAccount({
    required this.businessName,
    required this.contactName,
    required this.email,
    required this.sector,
    required this.city,
  });

  final String businessName;
  final String contactName;
  final String email;
  final String sector;
  final String city;

  CompanyAccount copyWith({
    String? businessName,
    String? contactName,
    String? email,
    String? sector,
    String? city,
  }) => CompanyAccount(
    businessName: businessName ?? this.businessName,
    contactName: contactName ?? this.contactName,
    email: email ?? this.email,
    sector: sector ?? this.sector,
    city: city ?? this.city,
  );

  Map<String, Object?> toJson() => {
    'businessName': businessName,
    'contactName': contactName,
    'email': email,
    'sector': sector,
    'city': city,
  };

  factory CompanyAccount.fromJson(Map<String, dynamic> json) => CompanyAccount(
    businessName: json['businessName'] as String,
    contactName: json['contactName'] as String,
    email: json['email'] as String,
    sector: json['sector'] as String,
    city: json['city'] as String,
  );
}
