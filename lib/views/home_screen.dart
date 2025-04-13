// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/app_controller.dart';
// import 'chat_screen.dart';
// // import 'history_screen.dart';
// // import 'reminders_screen.dart';
// // import 'notes_screen.dart';

// class HomeScreen extends StatelessWidget {
//   final AppController appController = Get.find();

//   HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => Scaffold(
//       body: IndexedStack(
//         index: appController.currentIndex.value,
//         children: [
//           ChatScreen(),
//           // HistoryScreen(),
//           // RemindersScreen(),
//           // NotesScreen(),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               blurRadius: 10,
//               spreadRadius: 0,
//             ),
//           ],
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//           child: BottomNavigationBar(
//             currentIndex: appController.currentIndex.value,
//             onTap: appController.changePage,
//             type: BottomNavigationBarType.fixed,
//             backgroundColor: Colors.white,
//             selectedItemColor: Colors.teal,
//             unselectedItemColor: Colors.grey.shade600,
//             selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//             unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
//             items: [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.chat_outlined),
//                 activeIcon: Icon(Icons.chat),
//                 label: 'Chat',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.history_outlined),
//                 activeIcon: Icon(Icons.history),
//                 label: 'History',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.calendar_today_outlined),
//                 activeIcon: Icon(Icons.calendar_today),
//                 label: 'Reminders',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.note_outlined),
//                 activeIcon: Icon(Icons.note),
//                 label: 'Notes',
//               ),
//             ],
//           ),
//         ),
//       ),
//     ));
//   }
// }
