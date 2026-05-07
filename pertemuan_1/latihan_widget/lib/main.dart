import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Hello Flutter!',
//               style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Ini teks biasa dengan ukuran kecil',
//               style: TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ));
// }


void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Container(
          width: 200,
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
                'Box',
                style: TextStyle(color: Colors.white, fontSize: 24)
            ),
          ),
        ),
      ),
    ),
  ));
}