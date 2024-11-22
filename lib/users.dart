import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addUsers() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Example list of users
  List<Map<String, dynamic>> users = [
    {
      "id": "user1", // This should ideally be the Firebase Authentication UID
      "name": "John Doe",
      "email": "johndoe@example.com",
      "orders": ["order1", "order2"], // List of order IDs (empty initially)
    },
    {
      "id": "user2",
      "name": "Jane Smith",
      "email": "janesmith@example.com",
      "orders": [],
    },
  ];

  for (var user in users) {
    await firestore.collection('users').doc(user['id']).set({
      "name": user['name'],
      "email": user['email'],
      "orders": user['orders'],
    });
  }

  print("Users added successfully!");
}
