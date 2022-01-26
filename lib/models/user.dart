import 'package:cloud_firestore/cloud_firestore.dart';

class MomentsUser {
  final String email;
  final String id;
  final String photoUrl;
  final String username;
  final String displayName;
  final String bio;
  final Map followers;
  final Map following;

  const MomentsUser(
      {required this.username,
      required this.id,
      required this.photoUrl,
      required this.email,
      required this.displayName,
      required this.bio,
      required this.followers,
      required this.following});

  factory MomentsUser.fromDocument(DocumentSnapshot document) {
    return MomentsUser(
      email: document['email'],
      username: document['username'],
      photoUrl: document['photoUrl'],
      id: document.get('id'),
      displayName: document['displayName'],
      bio: document['bio'],
      followers: document['followers'],
      following: document['following'],
    );
  }
}
