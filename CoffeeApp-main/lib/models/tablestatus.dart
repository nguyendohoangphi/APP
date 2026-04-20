class TableStatus {
  final String id;
  final String createDate;
  final String nameTable;
  late bool isBooked;
  late bool isVisible;

  TableStatus({
    required this.id,
    required this.createDate,
    required this.nameTable,
    required this.isBooked,
    this.isVisible = true,
  });

  factory TableStatus.fromJson(Map<String, dynamic> json) => TableStatus(
    id: json['id'],
    createDate: json['createDate'],
    nameTable: json['nameTable'],
    isBooked: json['isBooked'],
    isVisible: json['isVisible'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createDate': createDate,
    'nameTable': nameTable,
    'isBooked': isBooked,
    'isVisible': isVisible,
  };
}
