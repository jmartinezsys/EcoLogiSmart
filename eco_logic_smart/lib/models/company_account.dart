class CompanyAccount {
  const CompanyAccount({
    this.id = '',
    required this.businessName,
    required this.contactName,
    required this.email,
    required this.sector,
    required this.city,
  });

  final String id;
  final String businessName;
  final String contactName;
  final String email;
  final String sector;
  final String city;

  CompanyAccount copyWith({
    String? id,
    String? businessName,
    String? contactName,
    String? email,
    String? sector,
    String? city,
  }) => CompanyAccount(
    id: id ?? this.id,
    businessName: businessName ?? this.businessName,
    contactName: contactName ?? this.contactName,
    email: email ?? this.email,
    sector: sector ?? this.sector,
    city: city ?? this.city,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'businessName': businessName,
    'contactName': contactName,
    'email': email,
    'sector': sector,
    'city': city,
  };

  factory CompanyAccount.fromJson(Map<String, dynamic> json) => CompanyAccount(
    id: json['id'] as String? ?? '',
    businessName: json['businessName'] as String,
    contactName: json['contactName'] as String,
    email: json['email'] as String,
    sector: json['sector'] as String,
    city: json['city'] as String,
  );

  factory CompanyAccount.fromProfile(Map<String, dynamic> profile) =>
      CompanyAccount(
        id: profile['id'] as String,
        businessName: profile['business_name'] as String? ?? '',
        contactName: profile['contact_name'] as String? ?? '',
        email: profile['email'] as String? ?? '',
        sector: profile['sector'] as String? ?? 'Otro',
        city: profile['city'] as String? ?? '',
      );

  Map<String, Object?> toProfileJson() => {
    'business_name': businessName,
    'contact_name': contactName,
    'email': email,
    'sector': sector,
    'city': city,
  };
}
