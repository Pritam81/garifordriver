import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garifordriver/Assistants/assistants_methods.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/model/user_ride_request_information.dart';
import 'package:garifordriver/screens/Home/progressdialogue.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewTripScreen extends StatefulWidget {
  UserRideRequestInformation? userRideRequestDetails;
  NewTripScreen({required this.userRideRequestDetails});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  GoogleMapController? newtripGoogleMapController;
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  String ? buttontitle = "Arrived";
  Color ? buttonColor = Colors.green;
  Set<Marker> setMarkers = Set<Marker>();
  Set<Circle> setCircles = Set<Circle>();
  Set<Polyline> setPolylines = Set<Polyline>();
  List<LatLng> polyLinePostitionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlinedriverCurrentPosition;
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestingDirectionDetais = false;

  Future<void> drawPolylineFromOriginToDestination(
    LatLng originLatlng,
    LatLng destinationLatlng,
  ) async {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => progressDialogue(message: "Please wait..."),
    );

    var directionDetailsinfo =
        await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
          originLatlng,
          destinationLatlng,
        );
    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(
      directionDetailsinfo!.e_points!,
    );
    polyLinePostitionCoordinates.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        polyLinePostitionCoordinates.add(
          LatLng(pointLatLng.latitude, pointLatLng.longitude),
        );
      });
    }
    setPolylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polyLinePostitionCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );
      setPolylines.add(polyline);
    });

    LatLngBounds boundLatlng;
    if (originLatlng.latitude > destinationLatlng.latitude &&
        originLatlng.longitude > destinationLatlng.longitude) {
      boundLatlng = LatLngBounds(
        southwest: destinationLatlng,
        northeast: originLatlng,
      );
    } else if (originLatlng.longitude > destinationLatlng.longitude) {
      boundLatlng = LatLngBounds(
        southwest: LatLng(originLatlng.latitude, destinationLatlng.longitude),
        northeast: LatLng(destinationLatlng.latitude, originLatlng.longitude),
      );
    } else if (originLatlng.latitude > destinationLatlng.latitude) {
      boundLatlng = LatLngBounds(
        southwest: LatLng(destinationLatlng.latitude, originLatlng.longitude),
        northeast: LatLng(originLatlng.latitude, destinationLatlng.longitude),
      );
    } else {
      boundLatlng = LatLngBounds(
        southwest: originLatlng,
        northeast: destinationLatlng,
      );
    }
    newtripGoogleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(boundLatlng, 70),
    );
    Marker originMarker = Marker(
      markerId: MarkerId("origin"),
      position: originLatlng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: "Origin",
        snippet: "${originLatlng.latitude}, ${originLatlng.longitude}",
      ),
    );
    Marker destinationMarker = Marker(
      markerId: MarkerId("destination"),
      position: destinationLatlng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: "Destination",
        snippet:
            "${destinationLatlng.latitude}, ${destinationLatlng.longitude}",
      ),
    );
    setState(() {
      setMarkers.add(originMarker);
      setMarkers.add(destinationMarker);
    });
    Circle originCircle = Circle(
      circleId: CircleId("originID"),
      fillColor: Colors.greenAccent,
      center: originLatlng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.greenAccent,
    );
    Circle destinationCircle = Circle(
      circleId: CircleId("destinationID"),
      fillColor: Colors.redAccent,
      center: destinationLatlng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.redAccent,
    );
    setState(() {
      setCircles.add(originCircle);
      setCircles.add(destinationCircle);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    saveAssignedDriverDetailsToUserRideRequest();
  }

  createDriverIconMarker() {
    if (iconAnimatedMarker == null) {
      ImageConfiguration configuration = createLocalImageConfiguration(
        context,
        size: Size(2, 2),
      );
      BitmapDescriptor.fromAssetImage(
        configuration,
        "assets/images/car_topview.png",
      ).then((value) {
        iconAnimatedMarker = value;
      });
    }
  }

  saveAssignedDriverDetailsToUserRideRequest() async {
    DatabaseReference databaseReference = FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!);
    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };

    if (databaseReference.child("driverId") != "waiting") {
      databaseReference.child("driverLocation").set(driverLocationDataMap);
      databaseReference.child("status").set("accepted");
      databaseReference.child("driverId").set(onLineDriverData.id);
      databaseReference.child("driverName").set(onLineDriverData.name);
      databaseReference.child("driverPhone").set(onLineDriverData.phone);
      databaseReference
          .child("driverCarDetails")
          .set(
            onLineDriverData.carModel.toString() +
                " " +
                onLineDriverData.carNumber.toString() +
                " " +
                onLineDriverData.carColor.toString(),
          );

      saveRideRequestIdToDriverHistory();
    } else {
      Fluttertoast.showToast(
        msg:
            "Driver is not avvailabe for this ride request.\n Reloading the app",
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/splashScreen",
        (route) => false,
      );
    }
  }

  saveRideRequestIdToDriverHistory() {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(onLineDriverData.id!)
        .child("tripsHistory");
    tripsHistoryRef
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .set(true);
  }

  getdriverlocationUpdatesatrealtime() {
    LatLng oldlatlng = LatLng(0, 0);

    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream()
        .listen((Position position) {
          driverCurrentPosition = position;
          onlinedriverCurrentPosition = position;
          LatLng LatLngLiveDriverPosition = LatLng(
            onlinedriverCurrentPosition!.latitude,
            onlinedriverCurrentPosition!.longitude,
          );
          Marker animatedMarker = Marker(
            markerId: MarkerId("animatedMarker"),
            position: LatLngLiveDriverPosition,
            icon: iconAnimatedMarker!,
            infoWindow: InfoWindow(title: "This is your position"),
          );
          setState(() {
            CameraPosition cameraPosition = CameraPosition(
              target: LatLngLiveDriverPosition,
              zoom: 18,
            );
            newtripGoogleMapController!.animateCamera(
              CameraUpdate.newCameraPosition(cameraPosition),
            );
            setMarkers.removeWhere(
              (element) => element.markerId.value == "animatedMarker",
            );
            setMarkers.add(animatedMarker);
          });
          oldlatlng = LatLngLiveDriverPosition;
          updateDurationTimeAtRealtime();

          Map driverLatLngDataMap = {
            "latitude": onlinedriverCurrentPosition!.latitude.toString(),
            "longitude": onlinedriverCurrentPosition!.longitude.toString(),
          };
          FirebaseDatabase.instance
              .ref()
              .child("All Ride Requests")
              .child(widget.userRideRequestDetails!.rideRequestId!)
              .child("driverLocation")
              .set(driverLatLngDataMap);
        });
  }

  updateDurationTimeAtRealtime() async {
    if (isRequestingDirectionDetais == false) {
      isRequestingDirectionDetais = true;
      if (onlinedriverCurrentPosition == null) {
        return;
      }
      var originLatLng = LatLng(
        onlinedriverCurrentPosition!.latitude,
        onlinedriverCurrentPosition!.longitude,
      );
      var destinationLatLng;
      if (rideRequestStatus == "accepted") {
        destinationLatLng = widget.userRideRequestDetails!.originLatlng;
      } else {
        destinationLatLng = widget.userRideRequestDetails!.destinationLatlng;
      }

      var directionInformation =
          await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng,
            destinationLatLng!,
          );
      if (directionInformation != null) {
        setState(() {
          durationFromOriginToDestination = directionInformation.durationText!;
        });
      }
      isRequestingDirectionDetais = false;
    }
  }

  //280623
  @override
  Widget build(BuildContext context) {
    createDriverIconMarker();
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,

            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setMarkers,
            circles: setCircles,
            polylines: setPolylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              newtripGoogleMapController = controller;
              setState(() {
                mapPadding = 350;
              });

              var driverCurrentLatLng = LatLng(
                driverCurrentPosition!.latitude,
                driverCurrentPosition!.longitude,
              );

              var userPickUpLatlng =
                  widget.userRideRequestDetails!.originLatlng;

              drawPolylineFromOriginToDestination(
                driverCurrentLatLng!,
                userPickUpLatlng!,
              );
              getdriverlocationUpdatesatrealtime();
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(10),

              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Text(
                        "Estimated Time: $durationFromOriginToDestination",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "Brand-Bold",
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(height: 2, thickness: 2, color: Colors.grey[300]),
                      SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.userRideRequestDetails!.userName!,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Brand-Bold",
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: Icon(Icons.call)),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on),
                          Expanded(
                            child: Container(
                              child: Text(
                                widget.userRideRequestDetails!.originAddress!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "Brand-Bold",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on),
                          Expanded(
                            child: Container(
                              child: Text(
                                widget
                                    .userRideRequestDetails!
                                    .destinationAddress!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "Brand-Bold",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(height: 2, thickness: 2, color: Colors.grey[300]),

                      ElevatedButton.icon(onPressed: () {
                        if(rideRequestStatus=="accepted"){
                          rideRequestStatus = "arrived";
                          FirebaseDatabase.instance
                              .ref()
                              .child("All Ride Requests")
                              .child(widget.userRideRequestDetails!.rideRequestId!)
                              .child("status")
                              .set(rideRequestStatus);

                              setState(() {
                                buttontitle = "Start Trip";
                                buttonColor = Colors.green;
                              });

                              showDialog(context: context, builder: (BuildContext context) => progressDialogue(message: "Please wait..."),);


                        }
                      }
                      
                      
                      
                      , label: Text(
                        buttontitle!,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "Brand-Bold",
                        ),
                      ),
                        icon: Icon(Icons.check_circle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      
                       
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
