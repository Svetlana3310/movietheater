import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      });
    } catch (e) {
      print("Error fetching movie details: $e");
    }
  }

  void _showTrailerPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: YoutubePlayer(
          controller: YoutubePlayerController(
            initialVideoId: movieTrailerUrl,
            flags: YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
            ),
          ),
          showVideoProgressIndicator: true,
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

// Seating Chart Screen (Unchanged)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$movieTitle - ${widget.session}'),
      ),
      body: Column(
        children: [
          // Seat selection logic remains unchanged
        ],
      ),
    );
  }
}
