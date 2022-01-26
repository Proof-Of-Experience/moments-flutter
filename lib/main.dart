import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';

import 'models/user.dart';
import 'create_account.dart';

late MomentsUser? currentUserModel;
late PageController? pageController;
late FirebaseApp app;
late FirebaseAuth auth;
late CollectionReference<Map<String, dynamic>> ref;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).whenComplete(() {
    ref = FirebaseFirestore.instance.collection('moments_users');
    auth = FirebaseAuth.instance;
  });

  runApp(const Moments());
}

class Moments extends StatelessWidget {
  const Moments({Key? key}) : super(key: key);

  // Root widget for moments
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moments',
      // specifying theme data
      theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryIconTheme: const IconThemeData(color: Colors.black),
          textTheme: Theme.of(context)
              .textTheme
              .apply(bodyColor: Colors.black, displayColor: Colors.black)),
      home: const HomePage(title: 'Moments'),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Moments homepage
class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _page = 0;
  bool triedSilentLogin = false;
  bool setupNotifications = false;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    // Optional clientId
    // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  Future<void> _ensureLoggedIn(BuildContext context) async {
    GoogleSignInAccount? user = googleSignIn.currentUser;

    user ??= await googleSignIn.signInSilently();

    if (user == null) {
      await googleSignIn.signIn();
      await tryCreateUserRecord(context);
    }

    if (auth.currentUser == null) {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      await auth.signInWithCredential(credential);
    }
  }

  Future<void> _silentLogin(BuildContext context) async {
    GoogleSignInAccount? user = googleSignIn.currentUser;

    if (user == null) {
      user = await googleSignIn.signInSilently();
      await tryCreateUserRecord(context);
    }

    if (auth.currentUser == null && user != null) {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      await auth.signInWithCredential(credential);
    }
  }

  Future<void> tryCreateUserRecord(BuildContext context) async {
    GoogleSignInAccount? user = googleSignIn.currentUser;
    if (user == null) {
      return null;
    }

    DocumentSnapshot userRecord = await ref.doc(user.id).get();
    if (userRecord.exists == false) {
      // no user record exists, time to create
      String userName = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Center(
                  child: Scaffold(
                      appBar: AppBar(
                        leading: Container(),
                        title: const Text('Fill out missing data',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.white,
                      ),
                      body: ListView(
                        children: <Widget>[
                          Container(
                            child: CreateAccount(),
                          ),
                        ],
                      )),
                )),
      );

      if (userName != null || userName.length != 0) {
        ref.doc(user.id).set({
          "id": user.id,
          "username": userName,
          "photoUrl": user.photoUrl,
          "email": user.email,
          "displayName": user.displayName,
          "bio": "",
          "followers": {},
          "following": {},
        });
      }
      userRecord = await ref.doc(user.id).get();
    }

    currentUserModel = MomentsUser.fromDocument(userRecord);
  }

  Scaffold buildLoginPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 240.0),
          child: Column(
            children: <Widget>[
              const Text(
                'Moments',
                style: TextStyle(
                    fontSize: 60.0,
                    fontFamily: "Billabong",
                    color: Colors.black),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 100.0)),
              GestureDetector(
                onTap: login,
                child: Image.asset(
                  "assets/images/google_signin_button.png",
                  width: 225.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get bottomNavigationbar {
    return CupertinoTabBar(
      backgroundColor: Colors.amberAccent,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: (_page == 4) ? Colors.black : Colors.black),
            title: Container(height: 0.0),
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.search,
                color: (_page == 1) ? Colors.black : Colors.black),
            title: Container(height: 0.0),
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle,
                color: (_page == 2) ? Colors.black : Colors.black),
            title: Container(height: 0.0),
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.star,
                color: (_page == 3) ? Colors.black : Colors.black),
            title: Container(height: 0.0),
            backgroundColor: Colors.white),
        BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: (_page == 0) ? Colors.black : Colors.black),
            title: Container(height: 0.0),
            backgroundColor: Colors.white),
      ],
      onTap: navigationTapped,
      currentIndex: _page,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (triedSilentLogin == false) {
      silentLogin(context);
    }

    // if (setupNotifications == false && currentUserModel != null) {
    //   setUpNotifications();
    // }

    return (googleSignIn.currentUser == null || currentUserModel == null)
        ? buildLoginPage()
        : Scaffold(
            backgroundColor: Colors.black,
            body: PageView(
              children: [
                Container(
                  color: Colors.yellowAccent,
                  child: Container(),
                ),
              ],
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: onPageChanged,
            ),
            bottomNavigationBar: bottomNavigationbar,
          );
  }

  void login() async {
    await _ensureLoggedIn(context);
    setState(() {
      triedSilentLogin = true;
    });
  }

  // void setUpNotifications() {
  //   _setUpNotifications();
  //   setState(() {
  //     setupNotifications = true;
  //   });
  // }

  void silentLogin(BuildContext context) async {
    await _silentLogin(context);
    setState(() {
      triedSilentLogin = true;
    });
  }

  void navigationTapped(int page) {
    //Animating Page
    pageController?.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController?.dispose();
  }
}
