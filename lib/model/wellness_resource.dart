// class WellnessResource {
//   final String emoji;
//   final String title;
//   final String description;

//   WellnessResource({
//     required this.emoji,
//     required this.title,
//     required this.description,
//   });

//   factory WellnessResource.fromJson(Map<String, dynamic> json) {
//     return WellnessResource(
//       emoji: json['emoji'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'emoji': emoji,
//       'title': title,
//       'description': description,
//     };
//   }
// }