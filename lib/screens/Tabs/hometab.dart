import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garifordriver/Assistants/assistants_methods.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/model/drivermodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  String statusText = "Now offline";
  bool isDriverActive = false;
  Color buttonColor = Colors.redAccent;

  checkIfLocationPermissAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = cPosition;
    LatLng latLngPosition = LatLng(
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );

    CameraPosition cameraPosition = CameraPosition(
      target: latLngPosition,
      zoom: 14,
    );
    newGoogleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );

    String humanReadableAddress =
        await AssistantsMethods.searchAddressForGeographicCoordinates(
          driverCurrentPosition!,
          context,
        );
    print("This is your address: " + humanReadableAddress);
  }

  readCurrentDriverInfo() async {
    currentuser = firebaseauth.currentUser;
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentuser!.uid)
        .once()
        .then((snap) {
          if (snap.snapshot.value != null) {
            onLineDriverData.id = (snap.snapshot.value as Map)["id"];
            onLineDriverData.name = (snap.snapshot.value as Map)["name"];
            onLineDriverData.email = (snap.snapshot.value as Map)["email"];
            onLineDriverData.phone = (snap.snapshot.value as Map)["phone"];
            onLineDriverData.carColor =
                (snap.snapshot.value as Map)["car_color"];
            onLineDriverData.carModel =
                (snap.snapshot.value as Map)["car_model"];
            onLineDriverData.carNumber =
                (snap.snapshot.value as Map)["car_number"];
            driverVehicleType = (snap.snapshot.value as Map)["car_model"];
          } else {
            print("No data exists for this user.");
          }
        });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissAllowed();
    readCurrentDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: EdgeInsets.only(top: 40),
          mapType: MapType.normal,

          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            newGoogleMapController = controller;
            locateDriverPosition();
          },
        ),
        statusText != "Now Online"
            ? Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              color: Colors.black54,
            )
            : Container(),
        Positioned(
          top:
              statusText != "Now Online"
                  ? MediaQuery.of(context).size.height * 0.45
                  : 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (isDriverActive != true) {
                    driverIsOnlineNow();
                    updateDriverLocationAtRealTime();
                    setState(() {
                      statusText = "Now Online";
                      buttonColor = Colors.green;
                      isDriverActive = true;
                    });
                  } else {
                    driverIsOfflineNow();
                    setState(() {
                      statusText = "Now offline";
                      buttonColor = Colors.redAccent;
                      isDriverActive = false;
                    });
                    Fluttertoast.showToast(
                      msg: "your are offline now",
                      backgroundColor: buttonColor,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    statusText != "Now Online"
                        ? Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : Icon(
                          Icons.phonelink_ring,
                          color: Colors.white,
                          size: 30,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  driverIsOnlineNow() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = pos;
    Geofire.initialize("activeDrivers");
    Geofire.setLocation(
      currentuser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentuser!.uid)
        .child("newRideStatus");
    ref.set("idle");
    ref.onValue.listen((event) {});
  }

  updateDriverLocationAtRealTime() async {
    streamSubscriptionPosition = Geolocator.getPositionStream().listen((
      Position position,
    ) {
      if (isDriverActive == true) {
        Geofire.setLocation(
          currentuser!.uid,
          driverCurrentPosition!.latitude,
          driverCurrentPosition!.longitude,
        );
      }
      LatLng latlng = LatLng(
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude,
      );

      newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latlng));
    });
  }

  driverIsOfflineNow() {
    Geofire.removeLocation(currentuser!.uid);
    DatabaseReference? ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentuser!.uid)
        .child("newRideStatus");
    ref.onDisconnect();
    ref.remove();
    ref = null;
    Future.delayed(const Duration(milliseconds: 2000), () {
      //SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    });
  }
}
