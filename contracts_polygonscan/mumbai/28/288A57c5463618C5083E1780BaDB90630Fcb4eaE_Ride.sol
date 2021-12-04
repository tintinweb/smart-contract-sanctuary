// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import 'Ownable.sol';

interface Fare {
  struct RIDE_CONTRACT_SPLIT {
    string city_code;
    string car_type;
    uint256 initial_time;
    uint256 initial_distance;
    uint256 final_time;
    uint256 final_distance;
    address rider;
    address driver;
  }

  function storeBaseFare(
    uint256 ride_id,
    uint256 distance,
    uint256 time,
    uint256 boost_percent,
    string memory city_code,
    string memory car_type
  ) external;

  function storeEstimatedFare(uint256 ride_id, address driver) external;

  function addCounterQuote(
    uint256 boost_percent,
    uint256 ride_id,
    address driver
  ) external;

  function storeFinalFare(
    uint256 ride_id,
    uint256 final_fare,
    uint256 cgst,
    uint256 sgst,
    uint256 rider_referrer_amount,
    uint256 driver_referrer_amount,
    uint256 driver_earnings,
    uint256 base_fare_without_tax,
    uint256 premium_fare_without_tax
  ) external;

  function rideSplitFare(uint256 ride_id, string memory city_code) external;
}

contract Ride is Ownable {
  uint256 private id;
  address fare_contract_address;
  Fare fare_contract;
  struct RIDE_DATA {
    uint256 ride_id;
    uint256 ride_state; // [0,1,2,6,13]
    address rider;
    address driver;
    uint256 initial_distance;
    uint256 initial_time;
    uint256 final_distance;
    uint256 final_time;
    string city_code;
    string car_type;
    address[] eligibleDrivers;
  }

  struct RIDE_FARE_SPLIT {
    uint256 cgst;
    uint256 sgst;
    uint256 rider_referrer_amount;
    uint256 driver_referrer_amount;
    uint256 driver_earnings;
    uint256 base_fare_without_tax;
    uint256 premium_fare_without_tax;
  }

  struct DRIVER_DATA {
    address driver;
    bool is_processing;
  }

  struct RIDER_DATA {
    address rider;
    bool is_processing;
  }

  struct RIDE_REQUEST_SIGNATURE_OBJECT {
    address rider;
    address[] eligibleDrivers;
    uint256 initial_time;
    uint256 initial_distance;
    string city_code;
    string car_type;
    uint256 boost_percent;
  }

  mapping(address => bool) public is_driver_processing;
  mapping(address => bool) public is_rider_processing;
  mapping(uint256 => RIDE_DATA) rides;

  event Ride_Requested(address rider, uint256 ride_id);

  constructor(uint256 start_ride_id, address new_fare_contract_address) {
    id = start_ride_id;
    fare_contract_address = new_fare_contract_address;
    fare_contract = Fare(new_fare_contract_address);
  }

  modifier _isRiderBusy(address rider) {
    require(!currentRiderStatus(rider), 'Rider is in Ride');
    _;
  }

  modifier _isDriverBusy(address driver) {
    require(!currentDriverStatus(driver), 'Driver is in Ride');
    _;
  }

  modifier _rideExists(uint256 ride_id) {
    require(ride_id == rides[ride_id].ride_id, 'Ride Doesnot Exists');
    _;
  }

  modifier _driverIsEligible(uint256 ride_id, address driver) {
    require(checkEligibleDriver(ride_id, driver), 'Driver is not eligible');
    _;
  }

  modifier _isRider(uint256 ride_id) {
    require(_msgSender() == rides[ride_id].rider, 'User is not Rider');
    _;
  }

  modifier _isDriver(uint256 ride_id) {
    require(_msgSender() == rides[ride_id].driver, 'User is not Driver');
    _;
  }

  function setFareContractAddress(address new_fare_contract_address)
    public
    onlyOwner
  {
    fare_contract_address = new_fare_contract_address;

    fare_contract = Fare(new_fare_contract_address);
  }

  function currentRiderStatus(address rider) internal view returns (bool) {
    return is_rider_processing[rider];
  }

  function currentDriverStatus(address driver) internal view returns (bool) {
    return is_driver_processing[driver];
  }

  function createRideHash(
    uint256 initial_distance,
    uint256 initial_time,
    string memory city_code,
    string memory car_type,
    uint256 boost_percent,
    address[] memory eligibleDrivers
  ) public view returns (bytes32) {
    RIDE_REQUEST_SIGNATURE_OBJECT
      memory new_ride_signature_object = RIDE_REQUEST_SIGNATURE_OBJECT(
        _msgSender(),
        eligibleDrivers,
        initial_time,
        initial_distance,
        city_code,
        car_type,
        boost_percent
      );
    return keccak256(abi.encode(new_ride_signature_object));
  }

  function _getRideState(uint256 ride_id)
    internal
    view
    returns (uint256 ride_state)
  {
    ride_state = rides[ride_id].ride_state;
  }

  function requestRide(
    uint256 initial_distance,
    uint256 initial_time,
    string memory city_code,
    string memory car_type,
    uint256 boost_percent,
    address[] memory eligibleDrivers
  ) public _isRiderBusy(msg.sender) returns (uint256) {
    require(eligibleDrivers.length > 0, 'No eligible Drivers found');
    uint256 current_id = getId();
    uint256 new_ride_id = current_id + 1;
    // RIDE_REQUEST_SIGNATURE_OBJECT memory new_ride_signature_object = RIDE_REQUEST_SIGNATURE_OBJECT(_msgSender(), eligibleDrivers, initial_time, initial_distance, city_code, car_type, boost_percent);
    // bytes32 ride_request_hash = keccak256(abi.encode("\x19Ethereum Signed Message:\n32", new_ride_signature_object));

    //require(verifySignature(ride_request_signature, ride_request_hash, _msgSender()),"Ride signature is not Verified");
    // TODO: Signed object of ride data

    RIDE_DATA storage new_ride = rides[new_ride_id];
    new_ride.ride_id = new_ride_id;
    new_ride.rider = msg.sender;
    new_ride.initial_distance = initial_distance;
    new_ride.initial_time = initial_time;
    new_ride.city_code = city_code;
    new_ride.car_type = car_type;
    new_ride.eligibleDrivers = eligibleDrivers;
    new_ride.ride_state = 0;
    is_rider_processing[msg.sender] = true;
    Fare(fare_contract_address).storeBaseFare(
      new_ride_id,
      initial_distance,
      initial_time,
      boost_percent,
      city_code,
      car_type
    );
    incrementId();

    emit Ride_Requested(msg.sender, new_ride_id);
    return new_ride_id;
  }

  function counterQuote(uint256 boost_percent, uint256 ride_id)
    public
    _isDriverBusy(msg.sender)
    _rideExists(ride_id)
    _driverIsEligible(ride_id, _msgSender())
  {
    //TODO: to check if msg.sender is a eligible Driver

    //TODO: Check if ride_id is valid
    require(rides[ride_id].ride_state == 0, 'Invalid Ride State');
    fare_contract.addCounterQuote(boost_percent, ride_id, msg.sender);
  }

  function acceptRide(uint256 ride_id, address driver)
    public
    _isRider(ride_id)
    _driverIsEligible(ride_id, driver)
  {
    rides[ride_id].driver = driver;
    fare_contract.storeEstimatedFare(ride_id, driver);
    is_driver_processing[_msgSender()] = true;
    rides[ride_id].ride_state = 2;
  }

  function cancelRide(uint256 ride_id) public {
    RIDE_DATA memory ride_details = rides[ride_id];
    rides[ride_id].ride_state = 13;
    is_rider_processing[ride_details.rider] = false;
    is_driver_processing[ride_details.driver] = false;
  }

  function endRide(
    uint256 ride_id,
    uint256 distance,
    uint256 time,
    uint256 final_fare,
    uint256 cgst,
    uint256 sgst,
    uint256 rider_referrer_amount,
    uint256 driver_referrer_amount,
    uint256 driver_earnings,
    uint256 base_fare_without_tax,
    uint256 premium_fare_without_tax
  ) public {
    RIDE_DATA storage ride = rides[ride_id];
    require(ride.driver == _msgSender(), 'User is not a driver');

    ride.final_time = time;
    ride.final_distance = distance;

    fare_contract.storeFinalFare(
      ride_id,
      final_fare,
      cgst,
      sgst,
      rider_referrer_amount,
      driver_referrer_amount,
      driver_earnings,
      base_fare_without_tax,
      premium_fare_without_tax
    );
    is_rider_processing[ride.rider] = false;
    is_driver_processing[ride.driver] = false;

    rides[ride_id].ride_state = 6;
  }

  function incrementId() internal {
    id = id + 1;
  }

  function getId() internal view returns (uint256) {
    return id;
  }

  function checkEligibleDriver(uint256 ride_id, address driver)
    internal
    view
    returns (bool driverAvailable)
  {
    driverAvailable = false;
    for (uint256 i = 0; i < rides[ride_id].eligibleDrivers.length; i++) {
      if (rides[ride_id].eligibleDrivers[i] == driver) {
        driverAvailable = true;
      }
    }
  }

  function getRideDetails(uint256 _ride_id)
    public
    view
    returns (
      uint256 ride_id,
      uint256 ride_state,
      address rider,
      address driver,
      uint256 initial_distance,
      uint256 initial_time,
      uint256 final_distance,
      uint256 final_time,
      string memory city_code,
      string memory car_type,
      address[] memory eligibleDrivers
    )
  {
    RIDE_DATA memory ride_data = rides[_ride_id];
    ride_id = ride_data.ride_id;
    ride_state = ride_data.ride_state;
    rider = ride_data.rider;
    driver = ride_data.driver;
    initial_distance = ride_data.initial_distance;
    initial_time = ride_data.initial_time;
    final_distance = ride_data.final_distance;
    final_time = ride_data.final_time;
    city_code = ride_data.city_code;
    car_type = ride_data.car_type;
    eligibleDrivers = ride_data.eligibleDrivers;
  }

  function verifySignature(
    bytes32 _signature,
    bytes32 hash,
    address _user
  ) internal pure returns (bool verified) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    address recoveredAddress = ecrecover(hash, v, r, s);
    if (_user == recoveredAddress) {
      verified = true;
    } else {
      verified = false;
    }
  }

  function splitSignature(bytes32 sig)
    internal
    pure
    returns (
      bytes32 s,
      bytes32 r,
      uint8 v
    )
  {
    require(sig.length == 65, 'Invalid Singature Length');

    assembly {
      /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }
}