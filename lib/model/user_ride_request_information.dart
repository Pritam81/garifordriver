import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserRideRequestInformation {
  LatLng ? originLatlng;
  String ? originAddress;
  String ? destinationAddress;
  LatLng ? destinationLatlng;
  String ? rideRequestId;
  String ? userName;
  String ? userPhone;

  UserRideRequestInformation({
    this.originLatlng,
    this.originAddress,
    this.destinationAddress,
    this.destinationLatlng,
    this.rideRequestId,
    this.userName,
    this.userPhone,
  });



}