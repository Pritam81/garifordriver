import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/model/user_ride_request_information.dart';
import 'package:garifordriver/pushnotification/notification_dialog_box.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  Future initializeCloudMessaging(BuildContext context) async {
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? remoteMessage,
    ) {
      if (remoteMessage != null) {
        // Handle the message when the app is opened from a terminated state
        readuserRideRequestInformation(
          remoteMessage.data["rideRequestId"],
          context,
        );
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      // Handle the message when the app is in the foreground
      readuserRideRequestInformation(
        remoteMessage.data["rideRequestId"],
        context,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
      // Handle the message when the app is in the background and opened from a notification
      readuserRideRequestInformation(
        remoteMessage.data["rideRequestId"],
        context,
      );
    });
  }

  readuserRideRequestInformation(
    String userRideRequestId,
    BuildContext context,
  ) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child("driverId")
        .onValue
        .listen((event) {
          if (event.snapshot.value == "waiting" ||
              event.snapshot.value == firebaseauth.currentUser!.uid) {
            FirebaseDatabase.instance
                .ref()
                .child("All Ride Requests")
                .child(userRideRequestId)
                .once()
                .then((snapData) {
                  if (snapData.snapshot.value != null) {
                    double originLat = double.parse(
                      (snapData.snapshot.value as Map)["origin"]["latitude"],
                    );
                    double originLng = double.parse(
                      (snapData.snapshot.value as Map)["origin"]["longitude"],
                    );
                    String originAddress =
                        (snapData.snapshot.value as Map)["origin"]["address"];

                    double destinationLat = double.parse(
                      (snapData.snapshot.value
                          as Map)["destination"]["latitude"],
                    );
                    double destinationLng = double.parse(
                      (snapData.snapshot.value
                          as Map)["destination"]["longitude"],
                    );
                    String destinationAddress =
                        (snapData.snapshot.value
                            as Map)["destination"]["address"];

                    String userName =
                        (snapData.snapshot.value as Map)["userName"];
                    String userPhone =
                        (snapData.snapshot.value as Map)["userPhone"];
                    String rideReqeuestId = snapData.snapshot.key!;

                    UserRideRequestInformation userRideReuestdetails =
                        UserRideRequestInformation();

                    userRideReuestdetails.originLatlng = LatLng(
                      originLat,
                      originLng,
                    );
                    userRideReuestdetails.originAddress = originAddress;
                    userRideReuestdetails.destinationLatlng = LatLng(
                      destinationLat,
                      destinationLng,
                    );
                    userRideReuestdetails.destinationAddress =
                        destinationAddress;
                    userRideReuestdetails.userName = userName;
                    userRideReuestdetails.userPhone = userPhone;
                    userRideReuestdetails.rideRequestId = rideReqeuestId;

                    showDialog(
                      context: context,
                      builder:
                          (BuildContext context) => NotificationDialogBox(
                            userRideRequestDetails: userRideReuestdetails,
                          ),
                    );
                  } else {
                    Fluttertoast.showToast(msg: "Ride request does not exist.");
                  }

                  // Handle the ride request information
                });
          } else {
            Fluttertoast.showToast(
              msg: "This ride request has been cancelled.",
            );

            Navigator.pop(context);
          } // Navigate to the ride request screen or perform any action you want
        });
  }

  Future generateAndGetToken() async {
    String? registrationToken = await firebaseMessaging.getToken();
    print("fcm registration token: " + registrationToken!);
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("tokenId")
        .set(registrationToken);

        firebaseMessaging.subscribeToTopic("allDrivers");
    firebaseMessaging.subscribeToTopic("allUsers");
  }
}
