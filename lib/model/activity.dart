import 'package:flutter/material.dart';

class Activity {
  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonText;

  Activity({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonText,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: Icons.star, // Default icon
      buttonText: json['buttonText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
    };
  }
}