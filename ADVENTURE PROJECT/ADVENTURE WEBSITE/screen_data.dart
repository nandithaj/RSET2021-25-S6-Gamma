class ScreenData {
  final String name;
  bool isSelected = false; // Flag for checkbox selection

  ScreenData({required this.name});

  factory ScreenData.fromJson(Map<String, dynamic> json) => ScreenData(
        name: json['screen_name'] as String,
      );
}