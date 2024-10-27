class NotificationsColumn {
  static final List<String> values = [
    /// Add all fields
    entryId,
    address, time, carType, status
  ];

  static const String entryId = 'id';
  static const String address = 'address';
  static const String time = 'time';
  static const String carType = 'carType';
  static const String status = 'status';
}

class Notifications {
  late String entryId;
  late String address;
  late String time;
  late String carType;
  late String status;
  Notifications.empty();
  Notifications(
      {required this.entryId,
      required this.address,
      required this.time,
      required this.carType,
      required this.status});

  Notifications.fromMap(Map<String, dynamic> item)
      : entryId = item[NotificationsColumn.entryId],
        address = item[NotificationsColumn.address],
        time = item[NotificationsColumn.time],
        carType = item[NotificationsColumn.carType],
        status = item[NotificationsColumn.status];

  Map<String, Object> toMap() {
    return {
      NotificationsColumn.entryId: entryId,
      NotificationsColumn.address: address,
      NotificationsColumn.time: time,
      NotificationsColumn.carType: carType,
      NotificationsColumn.status: status,
    };
  }
}
