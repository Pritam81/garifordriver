import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garifordriver/Assistants/assistants_methods.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/model/user_ride_request_information.dart';
import 'package:garifordriver/screens/newtripscreen.dart';

class NotificationDialogBox extends StatefulWidget {
  UserRideRequestInformation userRideRequestDetails;
  NotificationDialogBox({super.key, required this.userRideRequestDetails});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              "New Ride Request",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "From: ${widget.userRideRequestDetails.originAddress}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              "To: ${widget.userRideRequestDetails.destinationAddress}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                acceptRideRequest(context);
                // Handle accept ride request
                Navigator.pop(context);
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }

  acceptRideRequest(BuildContext context) {
    // Logic to accept the ride request
    // For example, you can update the ride status in your database or perform any other action
    // Here, we are just printing a message to the console for demonstration purposes
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newRideStatus")
        .once()
        .then((snap) {
          if (snap.snapshot.value == "idle") {
            FirebaseDatabase.instance
                .ref()
                .child("drivers")
                .child(FirebaseAuth.instance.currentUser!.uid)
                .child("newRideStatus")
                .set("accepted");

            AssistantsMethods.pauseLiveLocationUpdated();
           Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewTripScreen(
                  userRideRequestDetails: widget.userRideRequestDetails,
                ),
              ),
            );
          } else {
            Fluttertoast.showToast(msg: "Ride request do not exixtes.");
          }
        });
  }
}
