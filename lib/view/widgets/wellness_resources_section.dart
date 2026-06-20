// import 'package:flutter/material.dart';
// import 'package:supporthive1/model/wellness_resource.dart';

// class WellnessResourcesSection extends StatelessWidget {
//   final List<WellnessResource> resources;
//   final Function(String) onOpenResource;

//   const WellnessResourcesSection({
//     super.key,
//     required this.resources,
//     required this.onOpenResource,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Wellness Resources',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           ...resources.asMap().entries.map((entry) {
//             final index = entry.key;
//             final resource = entry.value;
//             return Column(
//               children: [
//                 if (index > 0) const SizedBox(height: 12),
//                 _buildResourceItem(resource),
//               ],
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildResourceItem(WellnessResource resource) {
//     return InkWell(
//       onTap: () => onOpenResource(resource.title),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Text(resource.emoji, style: const TextStyle(fontSize: 24)),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     resource.title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     resource.description,
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
//           ],
//         ),
//       ),
//     );
//   }
// }