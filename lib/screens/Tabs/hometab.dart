import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:garifordriver/Assistants/assistants_methods.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/model/drivermodel.dart';
import 'package:garifordriver/pushnotification/push_notification_system.dart';
import 'package:garifordriver/screens/Tabs/customdrawer.dart';
import 'package:garifordriver/screens/main_page.dart';
import 'package:garifordriver/screens/newtripscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) return "";

    final startsWithDigit = RegExp(r'^\d');

    if (startsWithDigit.hasMatch(address)) {
      int commaIndex = address.indexOf(',');

      if (commaIndex != -1 && commaIndex + 1 < address.length) {
        return address.substring(commaIndex + 1).trim();
      }
    }

    return address;
  }

  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  String statusText = "Now offline";
  bool isDriverActive = false;
  Color buttonColor = Colors.redAccent;
  String driverStatus = "idle";
  String driverId = FirebaseAuth.instance.currentUser?.uid ?? "demo_id";

  LocationPermission? _locationPermission;
  StreamSubscription<Position>? positionStream;

  final DatabaseReference rideRequestRef = FirebaseDatabase.instance
      .ref()
      .child("All Ride Requests");

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    readCurrentDriverInfo();

    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializeCloudMessaging(context);
    pushNotificationSystem.generateAndGetToken();
  }

  checkIfLocationPermissionAllowed() async {
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
    newGoogleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  readCurrentDriverInfo() async {
    currentuser = firebaseauth.currentUser;
    if (currentuser != null) {
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentuser!.uid);
      DatabaseEvent event = await driverRef.once();
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        onLineDriverData = DriverData(
          id: data["id"],
          name: data["name"],
          email: data["email"],
          phone: data["phone"],
          carColor: data["car_color"],
          carModel: data["car_model"],
          carNumber: data["car_number"],
        );
        driverVehicleType = data["car_model"];
      }
    }
  }

  void showRideRequestDialog(Map requestInfo, String rideRequestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          title: Row(
            children: const [
              Icon(Icons.local_taxi, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text(
                "New Ride Request",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoChip(
                Icons.my_location,
                _formatAddress(requestInfo["originAddress"]),
                "Pickup",
              ),
              _infoChip(
                Icons.location_on,
                requestInfo["destinationAddress"],
                "Drop-off",
              ),
              _infoChip(Icons.person, requestInfo["userName"], "Name"),
              _infoChip(Icons.phone_android, requestInfo["userPhone"], "Phone"),
              _infoChip(Icons.access_time, requestInfo["time"], "Time"),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Accept"),
                  onPressed: () {
                    acceptRideRequest(rideRequestId, requestInfo);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text("Decline"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // This is the helper method
  Widget _infoChip(IconData icon, String? value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "$label: ${value ?? ''}",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> acceptRideRequest(String requestId, Map rideData) async {
    final requestRef = FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(requestId);
    await requestRef.update({"driverId": driverId});

    setState(() {
      driverStatus = "engaged";
    });

    Fluttertoast.showToast(msg: "Ride Accepted");

    LatLng origin = LatLng(
      double.parse(rideData["originLat"]),
      double.parse(rideData["originLng"]),
    );
    LatLng destination = LatLng(
      double.parse(rideData["destinationLat"]),
      double.parse(rideData["destinationLng"]),
    );

    //---------------------

    // FirebaseDatabase.instance
    //     .ref()
    //     .child("drivers")
    //     .child(firebaseauth.currentUser!.uid)
    //     .child("newRideStatus")
    //     .once()
    //     .then((snap) {
    //       if (snap.snapshot.value == "idle") {
    //         FirebaseDatabase.instance
    //             .ref()
    //             .child("drivers")
    //             .child(firebaseauth.currentUser!.uid)
    //             .child("newRideStatus")
    //             .set("accepted");
    //         AssistantsMethods.pauseLiveLocationUpdated();
    //         Navigator.of(context).push(
    //           MaterialPageRoute(
    //             builder: (context) => NewTripScreen(
    //              use
    //             ),
    //           ),
    //         );

    //       }
    //     });
  }

  void refreshPage() {
    Fluttertoast.showToast(msg: "Refreshing...");
    newGoogleMapController?.dispose();
    polylines.clear();
    markers.clear();
    setState(() {});
    listenToRideRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            padding: const EdgeInsets.only(top: 40),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            markers: markers,
            polylines: polylines,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (controller) {
              _controller.complete(controller);
              newGoogleMapController = controller;
              locateDriverPosition();
            },
          ),
          if (statusText != "Now Online")
            Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              color: Colors.black54,
            ),
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
                    if (!isDriverActive) {
                      goOnline();
                    } else {
                      goOffline();
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : const Icon(Icons.phonelink_ring, size: 30),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Builder(
              builder:
                  (context) => FloatingActionButton(
                    backgroundColor: const Color.fromARGB(255, 44, 183, 248),
                    onPressed: () {
                      Scaffold.of(context).openDrawer(); // Now this works
                    },
                    tooltip: "Open Drawer",
                    child: const Icon(Icons.menu, color: Colors.black),
                  ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 44, 183, 248),
              onPressed: refreshPage,
              tooltip: "Refresh",
              child: const Icon(Icons.refresh, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void goOnline() {
    driverIsOnlineNow();
    listenToRideRequests();
    updateDriverLocationAtRealTime();
    setState(() {
      statusText = "Now Online";
      buttonColor = Colors.green;
      isDriverActive = true;
    });
    Fluttertoast.showToast(msg: "You are online now");
  }

  void goOffline() {
    driverIsOfflineNow();
    setState(() {
      statusText = "Now offline";
      buttonColor = Colors.redAccent;
      isDriverActive = false;
    });
    Fluttertoast.showToast(msg: "You are offline now");
  }

  void driverIsOnlineNow() async {
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
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentuser!.uid)
        .child("newRideStatus")
        .set("idle");
  }

  void updateDriverLocationAtRealTime() {
    positionStream = Geolocator.getPositionStream().listen((position) {
      driverCurrentPosition = position;
      if (isDriverActive) {
        Geofire.setLocation(
          currentuser!.uid,
          driverCurrentPosition!.latitude,
          driverCurrentPosition!.longitude,
        );
      }
      LatLng latLng = LatLng(
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude,
      );
      newGoogleMapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  void driverIsOfflineNow() {
    Geofire.removeLocation(currentuser!.uid);
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentuser!.uid)
        .child("newRideStatus")
        .remove();
    positionStream?.cancel();
  }

  void listenToRideRequests() {
    rideRequestRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        Map request = event.snapshot.value as Map;
        if (request["driverId"] == "waiting" &&
            driverStatus == "idle" &&
            isDriverActive) {
          showRideRequestDialog(request, event.snapshot.key!);
        }
      }
    });
  }
}
