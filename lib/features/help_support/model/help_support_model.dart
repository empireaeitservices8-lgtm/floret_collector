class HelpSupportContactModel {
  final String email;
  final String phone;
  final String phoneFormatted;

  const HelpSupportContactModel({
    required this.email,
    required this.phone,
    required this.phoneFormatted,
  });

  factory HelpSupportContactModel.fromJson(Map<String, dynamic> json) {
    return HelpSupportContactModel(
      email: json['email']?.toString() ?? 'floretbilling@gmail.com',
      phone: json['phone']?.toString() ?? '94460 02666',
      phoneFormatted: json['phone_formatted']?.toString() ?? '+91 94460 02666',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'phone_formatted': phoneFormatted,
    };
  }
}

class SupportHoursModel {
  final String days;
  final String time;

  const SupportHoursModel({
    required this.days,
    required this.time,
  });

  factory SupportHoursModel.fromJson(Map<String, dynamic> json) {
    return SupportHoursModel(
      days: json['days']?.toString() ?? 'Monday to Saturday',
      time: json['time']?.toString() ?? '9:00 AM - 6:00 PM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'time': time,
    };
  }
}

class HelpSupportModel {
  final HelpSupportContactModel contact;
  final SupportHoursModel supportHours;
  final List<String> services;

  const HelpSupportModel({
    required this.contact,
    required this.supportHours,
    required this.services,
  });

  factory HelpSupportModel.fromJson(Map<String, dynamic> json) {
    return HelpSupportModel(
      contact: json['contact'] is Map
          ? HelpSupportContactModel.fromJson(
              Map<String, dynamic>.from(json['contact'] as Map))
          : const HelpSupportContactModel(
              email: 'floretbilling@gmail.com',
              phone: '94460 02666',
              phoneFormatted: '+91 94460 02666',
            ),
      supportHours: json['support_hours'] is Map
          ? SupportHoursModel.fromJson(
              Map<String, dynamic>.from(json['support_hours'] as Map))
          : const SupportHoursModel(
              days: 'Monday to Saturday',
              time: '9:00 AM - 6:00 PM',
            ),
      services: (json['services'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Billing inquiries',
            'Payment issues',
            'Waste collection scheduling',
            'Account support',
            'Technical assistance',
          ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact': contact.toJson(),
      'support_hours': supportHours.toJson(),
      'services': services,
    };
  }
}
