import 'package:flutter/foundation.dart';

@immutable
class CustomUser {
  const CustomUser({@required this.uid, this.displayName, this.photoUrl, this.email});

  final String uid;
  final String displayName, email, photoUrl;
}
