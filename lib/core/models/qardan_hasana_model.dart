class QardanHasanaApplication {
  final int id;
  final String applicationNo;
  final int applicantMemberId;
  final String applicantItsId;
  final String applicantName;
  final String applicantJamaat;
  final String? applicantOccupation;
  final String applicantMobile;
  final String? reason;
  final double amountRequested;
  final String? applicantSignatureUrl;
  final String? applicantPhotoUrl;
  final int captainMemberId;
  final String captainName;
  final String? captainMobile;
  final bool captainApproved;
  final String? captainApprovedAt;
  final int guarantorMemberId;
  final String guarantorName;
  final String? guarantorMobile;
  final String status;
  final String? formImageUrl;
  final double? sanctionedAmount;
  final double? installmentAmount;
  final int? numberOfMonths;
  final String? installmentDateFrom;
  final String? installmentDateTo;
  final String? adminSignatureUrl;
  final String? adminFormImageUrl;
  final int? adminApprovedBy;
  final String? adminApprovedAt;
  final String? rejectionReason;
  final bool termsAccepted;
  final String createdAt;
  final String updatedAt;

  QardanHasanaApplication({
    required this.id,
    required this.applicationNo,
    required this.applicantMemberId,
    required this.applicantItsId,
    required this.applicantName,
    required this.applicantJamaat,
    this.applicantOccupation,
    required this.applicantMobile,
    this.reason,
    required this.amountRequested,
    this.applicantSignatureUrl,
    this.applicantPhotoUrl,
    required this.captainMemberId,
    required this.captainName,
    this.captainMobile,
    this.captainApproved = false,
    this.captainApprovedAt,
    required this.guarantorMemberId,
    required this.guarantorName,
    this.guarantorMobile,
    required this.status,
    this.formImageUrl,
    this.sanctionedAmount,
    this.installmentAmount,
    this.numberOfMonths,
    this.installmentDateFrom,
    this.installmentDateTo,
    this.adminSignatureUrl,
    this.adminFormImageUrl,
    this.adminApprovedBy,
    this.adminApprovedAt,
    this.rejectionReason,
    this.termsAccepted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QardanHasanaApplication.fromJson(Map<String, dynamic> json) {
    return QardanHasanaApplication(
      id: json['id'] ?? 0,
      applicationNo: json['applicationNo'] ?? '',
      applicantMemberId: json['applicantMemberId'] ?? 0,
      applicantItsId: json['applicantItsId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantJamaat: json['applicantJamaat'] ?? '',
      applicantOccupation: json['applicantOccupation'],
      applicantMobile: json['applicantMobile'] ?? '',
      reason: json['reason'],
      amountRequested: (json['amountRequested'] ?? 0).toDouble(),
      applicantSignatureUrl: json['applicantSignatureUrl'],
      applicantPhotoUrl: json['applicantPhotoUrl'],
      captainMemberId: json['captainMemberId'] ?? 0,
      captainName: json['captainName'] ?? '',
      captainMobile: json['captainMobile'],
      captainApproved: json['captainApproved'] == true || json['captainApproved'] == 1,
      captainApprovedAt: json['captainApprovedAt'],
      guarantorMemberId: json['guarantorMemberId'] ?? 0,
      guarantorName: json['guarantorName'] ?? '',
      guarantorMobile: json['guarantorMobile'],
      status: json['status'] ?? 'pending',
      formImageUrl: json['formImageUrl'],
      sanctionedAmount: json['sanctionedAmount']?.toDouble(),
      installmentAmount: json['installmentAmount']?.toDouble(),
      numberOfMonths: json['numberOfMonths'],
      installmentDateFrom: json['installmentDateFrom'],
      installmentDateTo: json['installmentDateTo'],
      adminSignatureUrl: json['adminSignatureUrl'],
      adminFormImageUrl: json['adminFormImageUrl'],
      adminApprovedBy: json['adminApprovedBy'],
      adminApprovedAt: json['adminApprovedAt'],
      rejectionReason: json['rejectionReason'],
      termsAccepted: json['termsAccepted'] == true || json['termsAccepted'] == 1,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'submitted_to_admin':
        return 'Submitted';
      case 'sanctioned':
        return 'Sanctioned';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class QardanHasanaListItem {
  final int id;
  final String applicationNo;
  final int applicantMemberId;
  final String applicantName;
  final String applicantJamaat;
  final double amountRequested;
  final double? sanctionedAmount;
  final String status;
  final bool captainApproved;
  final int captainMemberId;
  final String createdAt;

  QardanHasanaListItem({
    required this.id,
    required this.applicationNo,
    required this.applicantMemberId,
    required this.applicantName,
    required this.applicantJamaat,
    required this.amountRequested,
    this.sanctionedAmount,
    required this.status,
    this.captainApproved = false,
    this.captainMemberId = 0,
    required this.createdAt,
  });

  factory QardanHasanaListItem.fromJson(Map<String, dynamic> json) {
    return QardanHasanaListItem(
      id: json['id'] ?? 0,
      applicationNo: json['applicationNo'] ?? '',
      applicantMemberId: json['applicantMemberId'] ?? 0,
      applicantName: json['applicantName'] ?? '',
      applicantJamaat: json['applicantJamaat'] ?? '',
      amountRequested: (json['amountRequested'] ?? 0).toDouble(),
      sanctionedAmount: json['sanctionedAmount']?.toDouble(),
      status: json['status'] ?? 'pending',
      captainApproved: json['captainApproved'] == true || json['captainApproved'] == 1,
      captainMemberId: json['captainMemberId'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'submitted_to_admin':
        return 'Submitted';
      case 'sanctioned':
        return 'Sanctioned';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class JamaatMember {
  final int id;
  final String fullName;
  final String? contact;
  final String itsId;

  JamaatMember({
    required this.id,
    required this.fullName,
    this.contact,
    required this.itsId,
  });

  factory JamaatMember.fromJson(Map<String, dynamic> json) {
    return JamaatMember(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      contact: json['contact'],
      itsId: json['itsId'] ?? '',
    );
  }
}
