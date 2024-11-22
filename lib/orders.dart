import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addOrders() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Example list of orders
  List<Map<String, dynamic>> orders = [
    {
      "id": "order1",
      "userId": "user1", // Reference to a user in the users collection
      "movieId": "movie1", // Reference to a movie in the movies collection
      "sessionTime": "10:00",
      "seats": ["row1-seat1", "row1-seat2"], // List of reserved seats
    },
    {
      "id": "order2",
      "userId": "user2",
      "movieId": "movie2",
      "sessionTime": "14:00",
      "seats": ["row2-seat5", "row2-seat6"],
    },
  ];

  for (var order in orders) {
    await firestore.collection('orders').doc(order['id']).set({
      "userId": order['userId'],
      "movieId": order['movieId'],
      "sessionTime": order['sessionTime'],
      "seats": order['seats'],
    });
  }

  print("Orders added successfully!");
}
