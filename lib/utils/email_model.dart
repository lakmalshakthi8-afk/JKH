class EngineEmail {
  final String toEmail;
  final String senderEmail;
  final String? subject;
  final String? senderName;
  final String? submittedContent;
  final String? campaignName;
  final List<Map<String, String>>? substitutionTags;
  final List<Map<String, String>>? attachments;
  final List<String>? ccEmails;
  final List<String>? bccEmails;

  EngineEmail({
    required this.toEmail,
    required this.senderEmail,
    this.subject,
    this.senderName,
    this.submittedContent,
    this.campaignName,
    this.substitutionTags,
    this.attachments,
    this.ccEmails,
    this.bccEmails,
  });

  /// Converts the object to a JSON map for the API request
  Map<String, dynamic> toJson() {
    return {
      'ToEmail': toEmail,
      'SenderEmail': senderEmail,
      if (subject != null) 'Subject': subject,
      if (senderName != null) 'SenderName': senderName,
      if (submittedContent != null) 'SubmittedContent': submittedContent,
      if (campaignName != null) 'CampaignName': campaignName,
      if (substitutionTags != null) 'SubstitutionTags': substitutionTags,
      if (attachments != null) 'Attachments': attachments,
      if (ccEmails != null) 'CCEmails': ccEmails,
      if (bccEmails != null) 'BCCEmails': bccEmails,
    };
  }
}
