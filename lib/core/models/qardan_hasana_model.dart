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
  final String? applicantProfile;
  final String? applicantMemberName;
  final int captainMemberId;
  final String captainName;
  final String? captainMobile;
  final String? captainItsId;
  final String? captainProfile;
  final bool captainApproved;
  final String? captainApprovedAt;
  final int guarantorMemberId;
  final String guarantorName;
  final String? guarantorMobile;
  final String? guarantorItsId;
  final String? guarantorProfile;
  final bool guarantorApproved;
  final String? guarantorApprovedAt;
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
    this.applicantMemberName,
    required this.applicantJamaat,
    this.applicantOccupation,
    required this.applicantMobile,
    this.reason,
    required this.amountRequested,
    this.applicantSignatureUrl,
    this.applicantPhotoUrl,
    this.applicantProfile,
    required this.captainMemberId,
    required this.captainName,
    this.captainMobile,
    this.captainItsId,
    this.captainProfile,
    this.captainApproved = false,
    this.captainApprovedAt,
    required this.guarantorMemberId,
    required this.guarantorName,
    this.guarantorMobile,
    this.guarantorItsId,
    this.guarantorProfile,
    this.guarantorApproved = false,
    this.guarantorApprovedAt,
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
      applicantMemberName: json['applicantMemberName'],
      applicantJamaat: json['applicantJamaat'] ?? '',
      applicantOccupation: json['applicantOccupation'],
      applicantMobile: json['applicantMobile'] ?? '',
      reason: json['reason'],
      amountRequested: (json['amountRequested'] ?? 0).toDouble(),
      applicantSignatureUrl: json['applicantSignatureUrl'],
      applicantPhotoUrl: json['applicantPhotoUrl'],
      applicantProfile: json['applicantProfile'],
      captainMemberId: json['captainMemberId'] ?? 0,
      captainName: json['captainName'] ?? '',
      captainMobile: json['captainMobile'],
      captainItsId: json['captainItsId'],
      captainProfile: json['captainProfile'],
      captainApproved: json['captainApproved'] == true || json['captainApproved'] == 1,
      captainApprovedAt: json['captainApprovedAt'],
      guarantorMemberId: json['guarantorMemberId'] ?? 0,
      guarantorName: json['guarantorName'] ?? '',
      guarantorMobile: json['guarantorMobile'],
      guarantorItsId: json['guarantorItsId'],
      guarantorProfile: json['guarantorProfile'],
      guarantorApproved: json['guarantorApproved'] == true || json['guarantorApproved'] == 1,
      guarantorApprovedAt: json['guarantorApprovedAt'],
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
  final bool guarantorApproved;
  final int captainMemberId;
  final int guarantorMemberId;
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
    this.guarantorApproved = false,
    this.captainMemberId = 0,
    this.guarantorMemberId = 0,
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
      guarantorApproved: json['guarantorApproved'] == true || json['guarantorApproved'] == 1,
      captainMemberId: json['captainMemberId'] ?? 0,
      guarantorMemberId: json['guarantorMemberId'] ?? 0,
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

/// A single recorded repayment / installment payment.
class QardanRepayment {
  final int id;
  final int qardanHasanaId;
  final int? installmentNumber;
  final double amountPaid;
  final String paymentDate;
  final String? paymentMode;
  final String? receiptImageUrl;
  final String? notes;
  final int? recordedBy;
  final String? recordedByName;
  final String createdAt;

  QardanRepayment({
    required this.id,
    required this.qardanHasanaId,
    this.installmentNumber,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentMode,
    this.receiptImageUrl,
    this.notes,
    this.recordedBy,
    this.recordedByName,
    required this.createdAt,
  });

  factory QardanRepayment.fromJson(Map<String, dynamic> json) {
    return QardanRepayment(
      id: json['id'] ?? 0,
      qardanHasanaId: json['qardanHasanaId'] ?? 0,
      installmentNumber: json['installmentNumber'],
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      paymentDate: json['paymentDate'] ?? '',
      paymentMode: json['paymentMode'],
      receiptImageUrl: json['receiptImageUrl'],
      notes: json['notes'],
      recordedBy: json['recordedBy'],
      recordedByName: json['recordedByName'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

/// Repayment summary for an application: how much is paid, pending and the
/// next installment date, along with the full payment history.
class QardanRepaymentSummary {
  final int qardanHasanaId;
  final String applicationNo;
  final String status;
  final double? sanctionedAmount;
  final double? installmentAmount;
  final int? numberOfMonths;
  final String? installmentDateFrom;
  final String? installmentDateTo;
  final double totalPaid;
  final double remainingAmount;
  final int paymentsCount;
  final int installmentsCovered;
  final bool isFullyPaid;
  final int? nextInstallmentNumber;
  final String? nextInstallmentDate;
  final double? nextInstallmentAmount;
  final List<QardanRepayment> repayments;

  QardanRepaymentSummary({
    required this.qardanHasanaId,
    required this.applicationNo,
    required this.status,
    this.sanctionedAmount,
    this.installmentAmount,
    this.numberOfMonths,
    this.installmentDateFrom,
    this.installmentDateTo,
    required this.totalPaid,
    required this.remainingAmount,
    required this.paymentsCount,
    required this.installmentsCovered,
    required this.isFullyPaid,
    this.nextInstallmentNumber,
    this.nextInstallmentDate,
    this.nextInstallmentAmount,
    this.repayments = const [],
  });

  factory QardanRepaymentSummary.fromJson(Map<String, dynamic> json) {
    return QardanRepaymentSummary(
      qardanHasanaId: json['qardanHasanaId'] ?? 0,
      applicationNo: json['applicationNo'] ?? '',
      status: json['status'] ?? '',
      sanctionedAmount: json['sanctionedAmount']?.toDouble(),
      installmentAmount: json['installmentAmount']?.toDouble(),
      numberOfMonths: json['numberOfMonths'],
      installmentDateFrom: json['installmentDateFrom'],
      installmentDateTo: json['installmentDateTo'],
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      paymentsCount: json['paymentsCount'] ?? 0,
      installmentsCovered: json['installmentsCovered'] ?? 0,
      isFullyPaid: json['isFullyPaid'] == true || json['isFullyPaid'] == 1,
      nextInstallmentNumber: json['nextInstallmentNumber'],
      nextInstallmentDate: json['nextInstallmentDate'],
      nextInstallmentAmount: json['nextInstallmentAmount']?.toDouble(),
      repayments: (json['repayments'] is List)
          ? (json['repayments'] as List)
              .map((e) => QardanRepayment.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
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
