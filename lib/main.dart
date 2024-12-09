import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'firebase_options.dart'; // Import the generated file
//import 'package:movietheater/movies.dart';
//import 'package:movietheater/users.dart';
//import 'package:movietheater/orders.dart';
//import 'package:movietheater/modify_movies.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  //await addMovies();
  //await addUsers();
  //await addOrders();
  // Define the updates for each document
  /*Map<String, Map<String, String>> updatedFields = {
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
      "title": "Кодове ім'я \"Червоний\"",
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
  };

  await modifyMovies(updatedFields); // Call the function with the updates
  */
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кінотеатр',
      home: MovieSelectionScreen(),
    );
  }
}

// Screen to select a movie
class MovieSelectionScreen extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Вибір фільму')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('movies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No movies available'));
          }

          final movies = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionSelectionScreen(movieId: movie.id),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          movie['image'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          movie['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Screen to select a session
class SessionSelectionScreen extends StatefulWidget {
  final String movieId;

  SessionSelectionScreen({required this.movieId});

  @override
  _SessionSelectionScreenState createState() => _SessionSelectionScreenState();
}

class _SessionSelectionScreenState extends State<SessionSelectionScreen> {
  String movieTitle = 'Loading...';
  String movieImage = '';
  String movieTrailerUrl = '';
  late YoutubePlayerController _youtubePlayerController;

  @override
  void initState() {
    super.initState();
    _fetchMovieDetails();
  }

  Future<void> _fetchMovieDetails() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot movieSnapshot =
          await firestore.collection('movies').doc(widget.movieId).get();

      setState(() {
        movieTitle = movieSnapshot.get('title');
        movieImage = movieSnapshot.get('image');
        movieTrailerUrl = YoutubePlayer.convertUrlToId(
            movieSnapshot.get('video'))!; // Extract YouTube video ID
        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: movieTrailerUrl,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      });
    } catch (e) {
      print("Error fetching movie details: $e");
    }
  }

  @override
  void dispose() {
    _youtubePlayerController.dispose();
    super.dispose();
  }

void _showTrailerPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.all(16), // Padding for the popup
      child: Stack(
        clipBehavior: Clip.none, // Allows the button to be positioned outside the dialog
        children: [
          // The YouTube Player
          YoutubePlayer(
            controller: YoutubePlayerController(
              initialVideoId: movieTrailerUrl,
              flags: YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
              ),
            ),
            showVideoProgressIndicator: true,
          ),
          // Close button, absolutely positioned
          Positioned(
            top: -20, // Slightly above the dialog
            right: -10, // 10px outside the right edge of the dialog
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black.withOpacity(0.6), // Background color
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}






  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text(movieTitle)),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('movies').doc(widget.movieId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No sessions available for this movie'));
          }

          final sessions =
              (snapshot.data!.data() as Map<String, dynamic>)['sessions'];

          return ListView(
            children: [
              Column(
                children: [
                  Image.network(movieImage, fit: BoxFit.cover),
                  ElevatedButton(
                    onPressed: () {
                      _showTrailerPopup(context);
                    },
                    child: Text("Play Trailer"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ...sessions.keys.map<Widget>((sessionTime) {
                return ListTile(
                  title: Text(sessionTime),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeatingChart(
                          movieId: widget.movieId,
                          session: sessionTime,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

// Screen to select seats
class SeatingChart extends StatefulWidget {
  final String movieId;
  final String session;

  SeatingChart({required this.movieId, required this.session});

  @override
  _SeatingChartState createState() => _SeatingChartState();
}

class _SeatingChartState extends State<SeatingChart> {
  final int rows = 8;
  final int seatsPerRow = 30;
  late List<List<bool>> _seats;
  Set<String> occupiedSeats = {};
  List<String> selectedSeats = [];
  String movieTitle = 'Loading...';

  @override
  void initState() {
    super.initState();
    _seats =
        List.generate(rows, (_) => List.generate(seatsPerRow, (_) => false));
    _fetchMovieDetails();
    _fetchOccupiedSeats();
  }

  Future<void> _fetchMovieDetails() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot movieSnapshot =
          await firestore.collection('movies').doc(widget.movieId).get();

      setState(() {
        movieTitle = movieSnapshot.get('title');
      });
    } catch (e) {
      print("Error fetching movie title: $e");
      setState(() {
        movieTitle = 'Unknown Movie';
      });
    }
  }

  Future<void> _fetchOccupiedSeats() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot movieSnapshot =
          await firestore.collection('movies').doc(widget.movieId).get();

      Map<String, dynamic> sessions = movieSnapshot.get('sessions');
      List<dynamic> occupiedSeatsList =
          sessions[widget.session]['occupiedSeats'];

      setState(() {
        occupiedSeats = occupiedSeatsList.cast<String>().toSet();
      });
    } catch (e) {
      print("Error fetching occupied seats: $e");
    }
  }

  Future<void> _processOrder() async {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No seats selected!")));
      return;
    }

    final userId = await showDialog<String>(
      context: context,
      builder: (context) => AuthDialog(),
    );

    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Order canceled")));
      return;
    }

    try {
      await _reserveSeats(userId);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error processing order: $e")));
    }
  }

  Future<void> _reserveSeats(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentReference movieRef =
          firestore.collection('movies').doc(widget.movieId);

      await firestore.runTransaction((transaction) async {
        DocumentSnapshot movieSnapshot = await transaction.get(movieRef);

        Map<String, dynamic> sessions = movieSnapshot.get('sessions');
        List<dynamic> currentOccupiedSeats =
            sessions[widget.session]['occupiedSeats'];

        for (String seat in selectedSeats) {
          if (currentOccupiedSeats.contains(seat)) {
            throw Exception("Seat $seat is already occupied!");
          }
        }

        currentOccupiedSeats.addAll(selectedSeats);

        transaction.update(movieRef, {
          'sessions.${widget.session}.occupiedSeats': currentOccupiedSeats,
        });
      });

      await firestore.collection('orders').add({
        'userId': userId,
        'movieId': widget.movieId,
        'session': widget.session,
        'seats': selectedSeats,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Order completed!")));
    } catch (e) {
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$movieTitle - ${widget.session}'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  for (int row = 0; row < rows; row++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int seat = 0; seat < seatsPerRow; seat++)
                          GestureDetector(
                            onTap: () {
                              String seatId = "row${row + 1}-seat${seat + 1}";
                              if (occupiedSeats.contains(seatId)) return;

                              setState(() {
                                _seats[row][seat] = !_seats[row][seat];
                                if (_seats[row][seat]) {
                                  selectedSeats.add(seatId);
                                } else {
                                  selectedSeats.remove(seatId);
                                }
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(4.0),
                              width: 30,
                              height: 30,
                              color: occupiedSeats
                                      .contains("row${row + 1}-seat${seat + 1}")
                                  ? Colors.red
                                  : _seats[row][seat]
                                      ? Colors.green
                                      : Colors.grey,
                              child: Center(
                                child: Text(
                                  '${row + 1}-${seat + 1}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _processOrder,
            child: Text("Order"),
          ),
        ],
      ),
    );
  }
}

// Dialog for user authentication
class AuthDialog extends StatefulWidget {
  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isEmailValid(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<String?> _signInOrSignUp() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill out all fields")));
      return null;
    }

    if (!_isEmailValid(email)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid email format")));
      return null;
    }

    try {
      QuerySnapshot userSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.id;
      }

      DocumentReference newUser = await firestore.collection('users').add({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser.id;
    } catch (e) {
      print("Error in sign-in/sign-up: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Sign In / Sign Up"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final userId = await _signInOrSignUp();
            Navigator.of(context).pop(userId);
          },
          child: Text("Submit"),
        ),
      ],
    );
  }
}