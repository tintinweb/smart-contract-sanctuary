// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import 'Ownable.sol';
import 'SafeMath.sol';

// interface DINR_Token {
//     struct RIDE_SPLIT_PAY {
//           address payee;
//           uint256 amount;
//      }
//     function mint(address account, uint256 amount) external;
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function freezeFare(uint256 amount, address beneficiary) external returns (bool) ;
//     function payAll(address payer, RIDE_SPLIT_PAY[] memory ride_split) external;
//     function unfreezeFare() external;
// }

// interface User {
//     function getUserReferrer(address user) external returns(address);
// }

contract Fare is Ownable {
  // Store fare based values City Params
  struct TAX {
    uint256 cgst;
    uint256 sgst;
  }

  // struct RIDE_SPLIT_PAY_FARE {
  //       DINR_Token.RIDE_SPLIT_PAY[] ride_split;
  //  }

  struct CAR_TYPE_PARAMS {
    string car_type_name;
    uint256 minimum_fare;
    uint256 time_multiplier;
    uint256 distance_multiplier;
  }

  uint256 private referral_percentage;
  address private tax_beneficary;
  address private ride_contract_address;
  //RIDE_SPLIT_PAY_FARE[] ride_s;
  //mapping (string => CAR_TYPE_PARAMS) public city_car_type_parameters;

  struct CITY_PARAMS {
    string city_code;
    uint256 minimum_distance;
    uint256 distance_buffer;
    uint256 time_buffer;
    TAX tax_parameters;
    bool set_car_parameters;
  }

  struct DRIVER_COUNTER_QUOTE {
    address driver;
    uint256 counter_quote_percent;
  }

  struct RIDE_FARE {
    uint256 ride_id;
    uint256 base_fare;
    uint256 boost_percent;
    uint256 chosen_mileage;
    uint256 estimated_fare;
    uint256 final_fare;
    mapping(address => DRIVER_COUNTER_QUOTE) counter_quotes;
    FARE_SPLIT fare_split_details;
    bool buffer_check;
  }

  struct SPLIT_PARAMS {
    uint256 csgt_deduction;
    uint256 sgst_deduction;
    uint256 fare_amount;
    uint256 premium_percent;
  }

  struct FARE_SPLIT {
    uint256 cgst;
    uint256 sgst;
    uint256 rider_referrer_amount;
    uint256 driver_referrer_amount;
    uint256 driver_earnings;
    uint256 base_fare_without_tax;
    uint256 premium_fare_without_tax;
  }

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

  struct RIDE_FARE_SPLIT_USERS {
    address rider_referrer;
    address driver_referrer;
    address driver;
    address drife;
  }

  mapping(string => mapping(string => CAR_TYPE_PARAMS)) public city_car_type;
  mapping(string => CITY_PARAMS) public city;
  mapping(uint256 => RIDE_FARE) public ride_fare;
  //DINR_Token private dinr_token_contract;
  //User private user_contract;

  event Base_Fare(uint256 ride_id, uint256 fare_amount);

  event Estimated_Fare(uint256 ride_id, uint256 fare_amount);

  event Final_Fare(uint256 ride_id, uint256 final_fare);

  event Fare_Split_Details(
    uint256 ride_id,
    uint256 cgst,
    uint256 sgst,
    uint256 rider_referrer_amount,
    uint256 driver_referrer_amount,
    uint256 driver_earnings,
    uint256 base_fare_without_tax,
    uint256 premium_fare_without_tax
  );

  constructor() {
    referral_percentage = 100;
    tax_beneficary = _msgSender();
    // dinr_token_contract = DINR_Token(dinr_token_address);
    // user_contract = User(user_contract_address);
  }

  modifier _cityExists(string memory city_code) {
    require(
      keccak256(abi.encodePacked(city[city_code].city_code)) ==
        keccak256(abi.encodePacked(city_code)),
      'City doesnot exists'
    );
    _;
  }

  modifier _carTypeExists(string memory city_code, string memory) {
    require(
      keccak256(abi.encodePacked(city[city_code].city_code)) ==
        keccak256(abi.encodePacked(city_code)),
      'City doesnot exists'
    );
    _;
  }

  modifier _isRideContract() {
    require(msg.sender == ride_contract_address, 'Invalid Call');
    _;
  }

  modifier _driverCounterQuoteExists(address driver, uint256 ride_id) {
    require(
      ride_fare[ride_id].counter_quotes[driver].driver == driver,
      'Driver is not eligible'
    );
    _;
  }

  function setRideContractAddress(address new_ride_contract_address) public {
    ride_contract_address = new_ride_contract_address;
  }

  function setCityParameter(
    string memory city_code,
    uint256 minimum_distance,
    uint256 distance_buffer,
    uint256 time_buffer,
    uint256 cgst,
    uint256 sgst
  ) public onlyOwner {
    TAX memory city_tax = TAX(cgst, sgst);
    CITY_PARAMS storage city_details = city[city_code];
    city_details.city_code = city_code;
    city_details.minimum_distance = minimum_distance;
    city_details.distance_buffer = distance_buffer;
    city_details.time_buffer = time_buffer;
    city_details.tax_parameters = city_tax;
    city_details.set_car_parameters = false;
    //city[city_code] = CITY_PARAMS(city_code, minimium_distance, distance_buffer, time_buffer, city_tax);
  }

  function setCityCarTyeParameters(
    string memory city_code,
    string memory car_type_name,
    uint256 minimum_fare,
    uint256 time_multiplier,
    uint256 distance_multiplier
  ) public onlyOwner {
    CAR_TYPE_PARAMS storage ct = city_car_type[city_code][car_type_name];
    ct.car_type_name = car_type_name;
    ct.minimum_fare = minimum_fare;
    ct.time_multiplier = time_multiplier;
    ct.distance_multiplier = distance_multiplier;
  }

  function getCityParameter(string memory _city_code)
    public
    view
    _cityExists(city_code)
    returns (
      string memory city_code,
      uint256 minimum_distance,
      uint256 distance_buffer,
      uint256 cgst,
      uint256 sgst
    )
  {
    CITY_PARAMS storage city_details = city[_city_code];
    TAX memory city_tax = city_details.tax_parameters;

    return (
      city_details.city_code,
      city_details.minimum_distance,
      city_details.distance_buffer,
      city_tax.cgst,
      city_tax.sgst
    );
  }

  function getCityCarTypeParameters(
    string memory city_code,
    string memory car_type_name
  )
    public
    view
    _cityExists(city_code)
    returns (
      string memory,
      uint256,
      uint256,
      uint256
    )
  {
    CAR_TYPE_PARAMS storage city_car_type_details = city_car_type[city_code][
      car_type_name
    ];
    return (
      city_car_type_details.car_type_name,
      city_car_type_details.minimum_fare,
      city_car_type_details.time_multiplier,
      city_car_type_details.distance_multiplier
    );
  }

  // Fare calculation
  function baseFareCalculation(
    string memory city_code,
    string memory car_type,
    uint256 time,
    uint256 distance
  ) public view _cityExists(city_code) returns (uint256 fare_after_tax) {
    CITY_PARAMS memory city_params = city[city_code];
    CAR_TYPE_PARAMS memory car_params = city_car_type[city_code][car_type];
    TAX memory tax_details = city_params.tax_parameters;

    // let distance_to_multiply: int = if (distance < state.city_fare_meta[city_code].minimum_distance) state.city_fare_meta[city_code].minimum_distance else distance
    uint256 distance_to_multiply = distance - city_params.minimum_distance;
    uint256 fare_before_tax = car_params.minimum_fare +
      (car_params.time_multiplier * time) +
      (car_params.distance_multiplier * distance_to_multiply) /
      uint256(1000);

    uint256 fare = fare_before_tax < car_params.minimum_fare
      ? car_params.minimum_fare
      : fare_before_tax;

    fare_after_tax =
      (fare * (uint256(10000) + tax_details.cgst + tax_details.sgst)) /
      uint256(10000);
  }

  function calculateEstimatedFare(uint256 fare_amount, uint256 mileage)
    internal
    pure
    returns (uint256 estimatedFare)
  {
    estimatedFare = ((mileage + 10000) * fare_amount) / 10000;
    return estimatedFare;
  }

  function getEstimatedFare(
    string memory city_code,
    string memory car_type,
    uint256 time,
    uint256 distance,
    uint256 mileage
  ) public view _cityExists(city_code) returns (uint256) {
    uint256 base_fare = baseFareCalculation(
      city_code,
      car_type,
      time,
      distance
    );
    uint256 estimatedFare = calculateEstimatedFare(base_fare, mileage);
    return estimatedFare;
  }

  function updateReferralPercentage(uint256 new_referrral_percentage) public {
    // TODO: Add limits
    referral_percentage = new_referrral_percentage;
  }

  function storeBaseFare(
    uint256 ride_id,
    uint256 distance,
    uint256 time,
    uint256 boost_percent,
    string memory city_code,
    string memory car_type
  ) external _isRideContract _cityExists(city_code) {
    /*
        TODO:
        1. Check if ride already Exist
        2. Check city_code car_type Parameters
        */

    RIDE_FARE storage new_ride_fare = ride_fare[ride_id];
    new_ride_fare.ride_id = ride_id;
    uint256 base_fare = baseFareCalculation(
      city_code,
      car_type,
      time,
      distance
    );

    new_ride_fare.base_fare = calculateEstimatedFare(base_fare, boost_percent);

    emit Base_Fare(ride_id, base_fare);
  }

  function addCounterQuote(
    uint256 boost_percent,
    uint256 ride_id,
    address driver
  ) external _isRideContract {
    /*
        TODO:
        1. Check if ride Exist
        */
    ride_fare[ride_id].counter_quotes[driver] = DRIVER_COUNTER_QUOTE(
      driver,
      boost_percent
    );
  }

  function storeEstimatedFare(uint256 ride_id, address driver)
    public
    _isRideContract
    _driverCounterQuoteExists(driver, ride_id)
  {
    ride_fare[ride_id].chosen_mileage = ride_fare[ride_id]
      .counter_quotes[driver]
      .counter_quote_percent;
    uint256 estimated_fare = calculateEstimatedFare(
      ride_fare[ride_id].base_fare,
      ride_fare[ride_id].counter_quotes[driver].counter_quote_percent
    );
    ride_fare[ride_id].estimated_fare = estimated_fare;
    //dinr_token_contract.freezeFare(ride_fare[ride_id].estimated_fare, tx.origin);
    emit Estimated_Fare(ride_id, estimated_fare);
  }

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
  ) external _isRideContract {
    // TODO: Add check id we need to recalculate final fare
    //CITY_PARAMS memory city_params = city[rcs.city_code];

    ride_fare[ride_id].fare_split_details = FARE_SPLIT(
      cgst,
      sgst,
      rider_referrer_amount,
      driver_referrer_amount,
      driver_earnings,
      base_fare_without_tax,
      premium_fare_without_tax
    );

    // bool buffer_check = absDifference(rcs.final_distance, rcs.initial_distance) <
    //   city_params.distance_buffer &&
    //   (
    //     SafeMath.div(
    //       SafeMath.mul(100, absDifference(rcs.initial_time, rcs.final_time)),
    //       rcs.initial_time
    //     )
    //   ) <
    //   city_params.time_buffer;
    // if (buffer_check) {
    //   final_fare = ride_fare[ride_id].estimated_fare;
    //   ride_fare[ride_id].final_fare = final_fare;
    // } else {

    //   uint256 new_base_fare = baseFareCalculation(
    //       rcs.city_code,
    //       rcs.car_type,
    //       rcs.final_time,
    //       rcs.final_distance
    //     );
    //   final_fare = calculateEstimatedFare(
    //     new_base_fare,
    //     ride_fare[ride_id].chosen_mileage
    //   );
    //   ride_fare[ride_id].final_fare = final_fare;
    // }
    // ride_fare[ride_id].buffer_check = buffer_check;
    // splitRideFare(ride_id, rcs.city_code);
    // disburseFare(ride_id, driver, rider);
    ride_fare[ride_id].final_fare = final_fare;
    emit Final_Fare(ride_id, final_fare);
    emit Fare_Split_Details(
      ride_id,
      cgst,
      sgst,
      driver_referrer_amount,
      rider_referrer_amount,
      driver_earnings,
      base_fare_without_tax,
      premium_fare_without_tax
    );
  }

  function splitRideFare(uint256 ride_id, string memory city_code)
    internal
    returns (
      uint256 cgst,
      uint256 sgst,
      uint256 rider_referrer_amount,
      uint256 driver_referrer_amount,
      uint256 driver_earnings,
      uint256 base_fare_without_tax,
      uint256 premium_fare_without_tax
    )
  {
    RIDE_FARE storage ride_details = ride_fare[ride_id];
    FARE_SPLIT memory fs = splitFare(
      ride_details.final_fare,
      city_code,
      ride_details.chosen_mileage
    );

    ride_details.fare_split_details = fs;
    emit Fare_Split_Details(
      ride_id,
      fs.cgst,
      fs.sgst,
      fs.rider_referrer_amount,
      fs.driver_referrer_amount,
      fs.driver_earnings,
      fs.base_fare_without_tax,
      fs.premium_fare_without_tax
    );
    return (
      fs.cgst,
      fs.sgst,
      fs.rider_referrer_amount,
      fs.driver_referrer_amount,
      fs.driver_earnings,
      fs.base_fare_without_tax,
      fs.premium_fare_without_tax
    );
  }

  // Split fare
  function splitFare(
    uint256 fare_amount,
    string memory city_code,
    uint256 premium_percent
  )
    internal
    view
    returns (
      //returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
      FARE_SPLIT memory fs
    )
  {
    CITY_PARAMS memory city_params = city[city_code];
    TAX memory tax_details = city_params.tax_parameters;

    SPLIT_PARAMS memory split_details = SPLIT_PARAMS(
      tax_details.cgst,
      tax_details.sgst,
      fare_amount,
      premium_percent
    );

    fs = splitFareCalculation(split_details);
  }

  function splitFareCalculation(SPLIT_PARAMS memory split_params)
    internal
    view
    returns (FARE_SPLIT memory final_fare_split)
  {
    (uint256 cgst_deduction, uint256 sgst_deduction) = taxDeductionAmount(
      split_params.fare_amount,
      split_params.csgt_deduction,
      split_params.csgt_deduction
    );
    uint256 fare_without_tax = SafeMath.sub(
      split_params.fare_amount,
      SafeMath.add(cgst_deduction, sgst_deduction)
    );

    uint256 base_fare_without_tax = (fare_without_tax * uint256(10000)) /
      (split_params.premium_percent + uint256(10000));

    uint256 premium_fare_without_tax = SafeMath.sub(
      fare_without_tax,
      base_fare_without_tax
    );

    uint256 referral_deduction = referralDeductionCalculation(fare_without_tax);

    uint256 rider_referral = SafeMath.div(referral_deduction, uint256(2));
    uint256 driver_referral = SafeMath.div(referral_deduction, uint256(2));

    uint256 driver_earnings = base_fare_without_tax - referral_deduction;

    final_fare_split = FARE_SPLIT(
      cgst_deduction,
      sgst_deduction,
      rider_referral,
      driver_referral,
      driver_earnings,
      base_fare_without_tax,
      premium_fare_without_tax
    );
  }

  function taxDeductionAmount(
    uint256 amount,
    uint256 cgst_tax_percentage,
    uint256 sgst_tax_percentage
  ) internal pure returns (uint256 cal_amount_cgst, uint256 cal_amount_sgst) {
    cal_amount_cgst = SafeMath.div(
      SafeMath.mul(amount, cgst_tax_percentage),
      10000
    );
    cal_amount_sgst = SafeMath.div(
      SafeMath.mul(amount, sgst_tax_percentage),
      10000
    );
    return (cal_amount_cgst, cal_amount_sgst);
  }

  function referralDeductionCalculation(uint256 fare)
    internal
    view
    returns (uint256 deduction)
  {
    deduction = SafeMath.div(
      SafeMath.mul(fare, referral_percentage),
      uint256(10000)
    );
  }

  function getRideFare(uint256 ride_id)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    RIDE_FARE storage ride_fare_details = ride_fare[ride_id];

    return (
      ride_fare_details.ride_id,
      ride_fare_details.base_fare,
      ride_fare_details.boost_percent,
      ride_fare_details.chosen_mileage,
      ride_fare_details.estimated_fare,
      ride_fare_details.final_fare
    );
  }

  function getRideSplitDetails(uint256 ride_id)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    FARE_SPLIT memory ride_split = ride_fare[ride_id].fare_split_details;
    return (
      ride_split.cgst,
      ride_split.sgst,
      ride_split.rider_referrer_amount,
      ride_split.driver_referrer_amount,
      ride_split.driver_earnings,
      ride_split.base_fare_without_tax,
      ride_split.premium_fare_without_tax
    );
  }

  // function disburseFare (uint256 ride_id, address driver, address rider) internal {

  //     //Get Ride SPlit details
  //     //DINR_Token.RIDE_SPLIT_PAY[] memory ride_s;
  //     FARE_SPLIT memory ride_split_details = ride_fare[ride_id].fare_split_details;

  //     // Get all Referrer's and beneficiaries
  //     // 1. Tax tax_beneficary
  //     DINR_Token.RIDE_SPLIT_PAY memory tax_beneficary_details = DINR_Token.RIDE_SPLIT_PAY(tax_beneficary, ride_split_details.cgst + ride_split_details.sgst);
  //     ride_s[ride_id].ride_split.push(tax_beneficary_details);

  //     // 2.Rider Referrer
  //     address rider_referrer = user_contract.getUserReferrer(rider);
  //     DINR_Token.RIDE_SPLIT_PAY memory rider_referrer_details = DINR_Token.RIDE_SPLIT_PAY(rider_referrer, ride_split_details.rider_referrer_amount);
  //     ride_s[ride_id].ride_split.push(rider_referrer_details);

  //     // 3.Driver Referrer
  //     address driver_referrer = user_contract.getUserReferrer(driver);
  //     DINR_Token.RIDE_SPLIT_PAY memory driver_referrer_details = DINR_Token.RIDE_SPLIT_PAY(driver_referrer, ride_split_details.driver_referrer_amount);
  //     ride_s[ride_id].ride_split.push(driver_referrer_details);

  //     // 4. Driver Earnings
  //     DINR_Token.RIDE_SPLIT_PAY memory driver_earnings = DINR_Token.RIDE_SPLIT_PAY(driver, ride_split_details.driver_earnings);
  //     ride_s[ride_id].ride_split.push(driver_earnings);

  //     dinr_token_contract.payAll(rider, ride_s[ride_id].ride_split);

  // }

  function absDifference(uint256 x, uint256 y)
    private
    pure
    returns (uint256 difference)
  {
    difference = x >= y ? SafeMath.sub(x, y) : SafeMath.sub(y, x);
    return difference;
  }
}