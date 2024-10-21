class NotificationsColumn {
  static final List<String> values = [
    /// Add all fields
    entry_id,
    address, time, carType, status
  ];

  static const String entry_id = 'id';
  static const String address = 'address';
  static const String time = 'time';
  static const String carType = 'carType';
  static const String status = 'status';
}

class Notifications {
  late String entry_id;
  late String address;
  late String time;
  late String carType;
  late String status;
  Notifications.empty();
  Notifications(
      {required this.entry_id,
      required this.address,
      required this.time,
      required this.carType,
      required this.status});

  Notifications.fromMap(Map<String, dynamic> item)
      : entry_id = item[NotificationsColumn.entry_id],
        address = item[NotificationsColumn.address],
        time = item[NotificationsColumn.time],
        carType = item[NotificationsColumn.carType],
        status = item[NotificationsColumn.status];

  Map<String, Object> toMap() {
    return {
      NotificationsColumn.entry_id: entry_id,
      NotificationsColumn.address: address,
      NotificationsColumn.time: time,
      NotificationsColumn.carType: carType,
      NotificationsColumn.status: status,
    };
  }
}
