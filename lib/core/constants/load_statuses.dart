class LoadStatus {
  static const String open = 'open';
  static const String assigned = 'assigned';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static String getLabel(String status) {
    switch (status) {
      case open:
        return 'Open / دستیاب';
      case assigned:
        return 'Assigned / تفویض شدہ';
      case inTransit:
        return 'In Transit / راستے میں';
      case delivered:
        return 'Delivered / پہنچ گیا';
      case cancelled:
        return 'Cancelled / منسوخ';
      default:
        return status;
    }
  }
}
