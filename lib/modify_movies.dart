import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> modifyMovies(Map<String, Map<String, String>> updatedFields) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fetch all documents in the 'movies' collection
  QuerySnapshot querySnapshot = await firestore.collection('movies').get();

  // Iterate through each document in the collection
  for (var doc in querySnapshot.docs) {
    String docId = doc.id;

    // Check if this document has updates defined in the updatedFields map
    if (updatedFields.containsKey(docId)) {
      Map<String, String> fields = updatedFields[docId]!;

      // Update the document with the provided fields
      await firestore.collection('movies').doc(docId).update({
        "title": fields["title"],
        "image": fields["image"],
        "video": fields["video"],
      });

      print("Document $docId updated with new fields: ${fields.toString()}");
    } else {
      print("No updates defined for document $docId");
    }
  }

  print("Movies update process completed!");
}

/* 
Use this function from your main program with a map of updates for each document.

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );

  // Define the updates for each document
  Map<String, Map<String, String>> updatedFields = {
    "movie1": {
      "title": "Wicked: Чародійка",
      "image": "https://multiplex.ua/images/02/42/024233986fa26ddd5780588e41e65953.jpeg",
      "video": "https://www.youtube.com/watch?v=FUOTfFFppos",
    },
    "movie2": {
      "title": "Гладіатор ІІ",
      "image": "https://multiplex.ua/images/0f/d7/0fd76a44d37467dadb503a60ed3db899.jpeg",
      "video": "https://www.youtube.com/watch?v=CfNx4EKIcyU",
    },
    "movie3": {
      "title": "Кодове ім'я "Червоний",
      "image": "https://multiplex.ua/images/57/0a/570a50d60c7d45633c7f026b22a0d053.jpeg",
      "video": "https://www.youtube.com/watch?v=gpjjdGMYo1k",
    },
    "movie4": {
      "title": "Веном: Останній танець",
      "image": "https://multiplex.ua/images/86/94/8694a5f64fdb5f116593cb53ac952a96.jpeg",
      "video": "https://www.youtube.com/watch?v=ji5jCOhztyQ",
    },
    "movie5": {
      "title": "Потік. Останній кіт на Землі",
      "image": "https://multiplex.ua/images/5f/86/5f86e9753eef5521be84e06e4e3048a3.jpeg",
      "video": "https://www.youtube.com/watch?v=cad341eGIfQ",
    },
    "movie6": {
      "title": "Жахаючий 3",
      "image": "https://multiplex.ua/images/b7/36/b736933608bef6ba422684adf5c6a35b.jpeg",
      "video": "https://www.youtube.com/watch?v=ZSd5eXPPNkU",
    },


    // Add more document-specific updates as needed
  };

  await modifyMovies(updatedFields); // Call the function with the updates
  runApp(MyApp());
}
*/
