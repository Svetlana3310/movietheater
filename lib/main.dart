import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Import the generated file
//import 'package:movietheater/movies.dart';
//import 'package:movietheater/users.dart';
//import 'package:movietheater/orders.dart';

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

          return ListView.builder(
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return ListTile(
                title: Text(movie['title']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionSelectionScreen(movieId: movie.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Screen to select a session
class SessionSelectionScreen extends StatelessWidget {
  final String movieId;

  SessionSelectionScreen({required this.movieId});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Вибір сеансу')),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('movies').doc(movieId).get(),
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
            children: sessions.keys.map<Widget>((sessionTime) {
              return ListTile(
                title: Text(sessionTime),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeatingChart(
                        movieId: movieId,
                        session: sessionTime,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
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