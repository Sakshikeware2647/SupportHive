import 'package:flutter/material.dart';

import 'ai_chat_screen.dart';
import 'peer_support_screen.dart';
import 'interns_screen.dart';
import 'experts_screen.dart';

import '../../widgets/counselling_card.dart';

class CounsellingScreen extends StatelessWidget {
  const CounsellingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Counselling"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔹 Header Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Counselling",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Choose your support path. From instant AI assistance to professional therapy.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // 🔹 AI ChatBot
            CounsellingCard(
              title: "AI ChatBot",
              subtitle: "24/7 Emotional Support",
              tag: "Always Available",
              color: Colors.purple,
              points: const [
                "24/7 availability",
                "Stress relief & relaxation",
                "Guided breathing exercises",
                "Safe, judgment-free space",
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIChatScreen(),
                  ),
                );
              },
            ),

            // 🔹 Peer Support
            CounsellingCard(
              title: "Peer Support",
              subtitle: "Connect with Understanding Peers",
              tag: "Community Support",
              color: Colors.blue,
              points: const [
                "Anonymous peer connections",
                "End-to-end encrypted chats",
                "Real-world shared experiences",
                "Nearby user matching",
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PeerSupportScreen(),
                  ),
                );
              },
            ),

            // 🔹 Interns
            CounsellingCard(
              title: "Interns",
              subtitle: "Student Counselors",
              tag: "Admin Verified",
              color: Colors.green,
              points: const [
                "Verified students only",
                "Real-time chat support",
                "Audio call capability",
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InternsScreen(),
                  ),
                );
              },
            ),

            // 🔹 Experts
            CounsellingCard(
              title: "Experts",
              subtitle: "Licensed Professionals",
              tag: "Professional Care",
              color: Colors.orange,
              points: const [
                "First 30 min chat FREE",
                "Video & audio calls",
                "Appointment scheduling",
                "Transparent fees",
              ],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpertsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔹 Privacy Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Privacy & Security Matters",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),

                  Text("🔒 End-to-End Encryption"),
                  Text("✔ Verified Professionals"),
                  Text("⏱ Flexible Access"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Quick Comparison
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Quick Comparison",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),

                  Text("AI Bot → 24/7, Free"),
                  Text("Peers → Community based"),
                  Text("Interns → Verified students"),
                  Text("Experts → Paid professionals"),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}