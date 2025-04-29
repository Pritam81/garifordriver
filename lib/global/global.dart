import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:garifordriver/model/drivermodel.dart';
import 'package:geolocator/geolocator.dart';

final FirebaseAuth firebaseauth = FirebaseAuth.instance;
User? currentuser;
var isLoggedin = false;
String userDropOffAddress = "";

Position? driverCurrentPosition;

DriverData onLineDriverData = DriverData();

String? driverVehicleType = " ";
StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;



