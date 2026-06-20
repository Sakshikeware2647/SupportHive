import 'package:flutter/material.dart';
import '../../../model/intern_model.dart';
import '../../../service/intern_service.dart';
import 'intern_chat_screen.dart';
import 'intern_call_screen.dart'; // ← use InternCallScreen, NOT CallScreen

class InternsScreen extends StatefulWidget {
  const InternsScreen({super.key});

  @override
  State<InternsScreen> createState() => _InternsScreenState();
}

class _InternsScreenState extends State<InternsScreen> {

  final InternService service = InternService();
  List<Intern> interns = [];

  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    interns = service.getInterns();
  }

  void quickConnect() {
    final available = interns.where((i) => i.isAvailable).toList();
    if (available.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InternChatScreen(intern: available.first),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Student Interns"),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Connect with trained psychology interns",
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          // QUICK CONNECT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardStyle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Need immediate help?"),
                ElevatedButton(
                  onPressed: quickConnect,
                  child: const Text("Quick Connect"),
                )
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FILTER
          Row(
            children: ["All", "Anxiety", "Stress"].map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e),
                  selected: selectedFilter == e,
                  onSelected: (_) => setState(() => selectedFilter = e),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // INTERN LIST
          ...interns.map((intern) => _internCard(intern)).toList(),
        ],
      ),
    );
  }

  Widget _internCard(Intern intern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(intern.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(intern.specialization),
          Text("⭐ ${intern.rating}"),
          const SizedBox(height: 10),
          Row(
            children: [

              // CHAT
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternChatScreen(intern: intern),
                  ),
                ),
                child: const Text("Chat"),
              ),

              const SizedBox(width: 10),

              // CALL — uses InternCallScreen (no expert/booking needed)
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InternCallScreen(intern: intern),
                  ),
                ),
                child: const Text("Call"),
              ),
            ],
          )
        ],
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    );
  }
}