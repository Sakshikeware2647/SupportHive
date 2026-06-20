import '../model/intern_model.dart';

class InternService {

  List<Intern> getInterns() {
    return [
      Intern(
        name: "Sarah Mitchell",
        email: "sarah@gmail.com",
        specialization: "Anxiety | Stress",
        rating: 4.8,
        isAvailable: true,
      ),
      Intern(
        name: "Priya Sharma",
        email: "priya@gmail.com",
        specialization: "CBT | Career",
        rating: 4.9,
        isAvailable: true,
      ),
      Intern(
        name: "Alex Thompson",
        email: "alex@gmail.com",
        specialization: "Depression | Anxiety",
        rating: 4.7,
        isAvailable: false,
      ),
    ];
  }
}