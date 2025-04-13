// import 'package:flutter/material.dart';

// class Box extends StatelessWidget {
//   final String primaryText;
//   final String secondaryText;
//   Box({
//     super.key,
//     required this.primaryText,
//     required this.secondaryText,
//   });

//   Color lightBlue = Color(0xFFB4DBFF); // Placeholder for image
//   Color softBlue = Color(0xFFEAF2FF);
//   @override
//   Widget build(BuildContext context) {
//     double width =
//         (MediaQuery.of(context).size.width / 2) - 20; // Dynamic width
//     return GestureDetector(
//       onTap: () {
//         // later
//       },
//       child: Container(
//         width: width,
//         height: width, // Keeping it square based on screen width
//         margin: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Colors.white, // Background color (optional)
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: width * (2 / 3), // 2/3 of the dynamic width
//               decoration: BoxDecoration(
//                 color: lightBlue,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: softBlue,
//                   borderRadius:
//                       const BorderRadius.vertical(bottom: Radius.circular(16)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'secondary text long long long long',
//                       style: TextStyle(fontSize: 14, color: Colors.black54),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       "primaryText long long long",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
