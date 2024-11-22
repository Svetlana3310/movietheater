import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addMovies() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Define your movies and their sessions
  List<Map<String, dynamic>> movies = [
    {
      "id": "movie1",
      "title": "Movie 1",
      "description": "An exciting action movie",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "14:00": {"occupiedSeats": []},
        "18:00": {"occupiedSeats": []},
        "21:00": {"occupiedSeats": []},
      }
    },
    {
      "id": "movie2",
      "title": "Movie 2",
      "description": "A heartwarming drama",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "13:00": {"occupiedSeats": []},
        "16:00": {"occupiedSeats": []},
        "20:00": {"occupiedSeats": []},
      }
    },
    {
      "id": "movie3",
      "title": "Movie 3",
      "description": "A heartwarming drama",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "13:00": {"occupiedSeats": []},
        "16:00": {"occupiedSeats": []},
        "20:00": {"occupiedSeats": []},
      }
    },
    {
      "id": "movie4",
      "title": "Movie 4",
      "description": "A heartwarming drama",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "13:00": {"occupiedSeats": []},
        "16:00": {"occupiedSeats": []},
        "20:00": {"occupiedSeats": []},
      }
    },
    {
      "id": "movie5",
      "title": "Movie 5",
      "description": "A heartwarming drama",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "13:00": {"occupiedSeats": []},
        "16:00": {"occupiedSeats": []},
        "20:00": {"occupiedSeats": []},
      }
    },
    {
      "id": "movie6",
      "title": "Movie 6",
      "description": "A heartwarming drama",
      "sessions": {
        "10:00": {"occupiedSeats": []},
        "13:00": {"occupiedSeats": []},
        "16:00": {"occupiedSeats": []},
        "20:00": {"occupiedSeats": []},
      }
    },
    // Add more movies here
  ];

  // Add each movie to the Firestore database
  for (var movie in movies) {
    await firestore.collection('movies').doc(movie['id']).set({
      "title": movie['title'],
      "description": movie['description'],
      "sessions": movie['sessions'],
    });
  }

  print("Movies added successfully!");
}
/* 
Do like this to create movie collection in firebase. This it a main from main dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  await addMovies();
  runApp(MyApp());
}
*/