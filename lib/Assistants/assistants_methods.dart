import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:garifordriver/Assistants/request_assistant.dart';
import 'package:garifordriver/global/global.dart';
import 'package:garifordriver/global/map_key.dart';
import 'package:garifordriver/infoHandler/app_info.dart';
import 'package:garifordriver/model/direction.dart';
import 'package:garifordriver/model/directiondetails.dart';
import 'package:garifordriver/model/usermodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:provider/provider.dart';

class AssistantsMethods {
  static void readCurrentOnlineUserInfo() async {
    currentuser = FirebaseAuth.instance.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentuser!.uid);

    userRef.once().then((userSnapshot) {
      if (userSnapshot.snapshot.value != null) {
        var userModelCurrentInfo = Usermodel.fromSnapshot(
          userSnapshot.snapshot,
        );
      } else {
        print("No data exists for this user.");
      }
    });
  }

  static Future<String> searchAddressForGeographicCoordinates(
    Position position,
    context,
  ) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    var requestResponse = await RequestAssistant.getRequest(apiUrl);

    if (requestResponse != "Error Occured. Failed.  No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];
      print("This is your address: " + humanReadableAddress);

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;

      userPickUpAddress.locationName = humanReadableAddress;
      Provider.of<AppInfo>(
        context,
        listen: false,
      ).updatePickUpLocationAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }

  static double calculateFaresFromOriginToDestination(
    Directiondetailsinfo directionDetailsInfo,
  ) {
    double timeTraveledFareAmountPerMinute =
        (directionDetailsInfo.durationValue! / 60) * 0.1;
    double distanceTraveledFareAmountPerKilometer =
        (directionDetailsInfo.distanceValue! / 1000) * 0.1;

    double totalAmount =
        timeTraveledFareAmountPerMinute +
        distanceTraveledFareAmountPerKilometer;
    double totalLocalAmount = double.parse(totalAmount.toStringAsFixed(2));
    return totalLocalAmount;
  }

  static Future<Directiondetailsinfo?>
  obtainOriginToDestinationDirectionDetails(
    LatLng originPosition,
    LatLng destinationPosition,
  ) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";

    var responseDirectionApi = await RequestAssistant.getRequest(
      urlOriginToDestinationDirectionDetails,
    );

    if (responseDirectionApi == "Error Occured. Failed.  No Response.") {
      return null;
    }
    Directiondetailsinfo directionDetailsInfo = Directiondetailsinfo();
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];
    directionDetailsInfo.distanceText =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distanceValue =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
    directionDetailsInfo.durationText =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.durationValue =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static pauseLiveLocationUpdated() {
    streamSubscriptionPosition!.pause();
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
    
  }
}
