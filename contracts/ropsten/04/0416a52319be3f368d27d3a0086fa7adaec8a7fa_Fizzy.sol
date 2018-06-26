pragma solidity ^0.4.19;

contract Fizzy {
  /*
  * Potential statuses for the Insurance struct
  * 0: ongoing
  * 1: insurance contract resolved normaly and the flight landed before the limit
  * 2: insurance contract resolved normaly and the flight landed after the limit
  * 3: insurance contract resolved because cancelled by the user
  * 4: insurance contract resolved because flight cancelled by the air company
  * 5: insurance contract resolved because flight redirected
  * 6: insurance contract resolved because flight diverted
  */
  struct Insurance {          // all the infos related to a single insurance
    bytes32 productId;           // ID string of the product linked to this insurance
    uint limitArrivalTime;    // maximum arrival time after which we trigger compensation (timestamp in sec)
    uint32 premium;           // amount of the premium
    uint32 indemnity;         // amount of the indemnity
    uint8 status;             // status of this insurance contract. See comment above for potential values
  }

  event InsuranceCreation(    // event sent when a new insurance contract is added to this smart contract
    bytes32 flightId,         // <carrier_code><flight_number>.<timestamp_in_sec_of_departure_date>
    uint32 premium,           // amount of the premium paid by the user
    uint32 indemnity,         // amount of the potential indemnity
    bytes32 productId            // ID string of the product linked to this insurance
  );

  /*
   * Potential statuses for the InsuranceUpdate event
   * 1: flight landed before the limit
   * 2: flight landed after the limit
   * 3: insurance contract cancelled by the user
   * 4: flight cancelled
   * 5: flight redirected
   * 6: flight diverted
   */
  event InsuranceUpdate(      // event sent when the situation of a particular insurance contract is resolved
    bytes32 productId,           // id string of the user linked to this account
    bytes32 flightId,         // <carrier_code><flight_number>.<timestamp_in_sec_of_departure_date>
    uint32 premium,           // amount of the premium paid by the user
    uint32 indemnity,         // amount of the potential indemnity
    uint8 status              // new status of the insurance contract. See above comment for potential values
  );

  address creator;            // address of the creator of the contract

  // All the insurances handled by this smart contract are contained in this mapping
  // key: a string containing the flight number and the timestamp separated by a dot
  // value: an array of insurance contracts for this flight
  mapping (bytes32 => Insurance[]) insuranceList;


  // ------------------------------------------------------------------------------------------ //
  // MODIFIERS / CONSTRUCTOR
  // ------------------------------------------------------------------------------------------ //

  /**
   * @dev This modifier checks that only the creator of the contract can call this smart contract
   */
  modifier onlyIfCreator {
    if (msg.sender == creator) _;
  }

  /**
   * @dev Constructor
   */
  function Fizzy() public {
    creator = msg.sender;
  }


  // ------------------------------------------------------------------------------------------ //
  // INTERNAL FUNCTIONS
  // ------------------------------------------------------------------------------------------ //

  function areStringsEqual (bytes32 a, bytes32 b) private pure returns (bool) {
    // generate a hash for each string and compare them
    return keccak256(a) == keccak256(b);
  }


  // ------------------------------------------------------------------------------------------ //
  // FUNCTIONS TRIGGERING TRANSACTIONS
  // ------------------------------------------------------------------------------------------ //

  /**
   * @dev Add a new insurance for the given flight
   * @param flightId <carrier_code><flight_number>.<timestamp_in_sec_of_departure_date>
   * @param limitArrivalTime Maximum time after which we trigger the compensation (timestamp in sec)
   * @param premium Amount of premium paid by the client
   * @param indemnity Amount (potentialy) perceived by the client
   * @param productId ID string of product linked to the insurance
   */
  function addNewInsurance(
    bytes32 flightId,
    uint limitArrivalTime,
    uint32 premium,
    uint32 indemnity,
    bytes32 productId)
  public
  onlyIfCreator {

    Insurance memory insuranceToAdd;
    insuranceToAdd.limitArrivalTime = limitArrivalTime;
    insuranceToAdd.premium = premium;
    insuranceToAdd.indemnity = indemnity;
    insuranceToAdd.productId = productId;
    insuranceToAdd.status = 0;

    insuranceList[flightId].push(insuranceToAdd);

    // send an event about the creation of this insurance contract
    InsuranceCreation(flightId, premium, indemnity, productId);
  }

  /**
   * @dev Update the status of a flight
   * @param flightId <carrier_code><flight_number>.<timestamp_in_sec_of_departure_date>
   * @param actualArrivalTime The actual arrival time of the flight (timestamp in sec)
   */
  function updateFlightStatus(
    bytes32 flightId,
    uint actualArrivalTime)
  public
  onlyIfCreator {

    uint8 newStatus = 1;

    // go through the list of all insurances related to the given flight
    for (uint i = 0; i < insuranceList[flightId].length; i++) {

      // we check this contract is still ongoing before updating it
      if (insuranceList[flightId][i].status == 0) {

        newStatus = 1;

        // if the actual arrival time is over the limit the user wanted,
        // we trigger the indemnity, which means status = 2
        if (actualArrivalTime > insuranceList[flightId][i].limitArrivalTime) {
          newStatus = 2;
        }

        // update the status of the insurance contract
        insuranceList[flightId][i].status = newStatus;

        // send an event about this update for each insurance
        InsuranceUpdate(
          insuranceList[flightId][i].productId,
          flightId,
          insuranceList[flightId][i].premium,
          insuranceList[flightId][i].indemnity,
          newStatus
        );
      }
    }
  }

  /**
   * @dev Manually resolve an insurance contract
   * @param flightId <carrier_code><flight_number>.<timestamp_in_sec_of_departure_date>
   * @param newStatusId ID of the resolution status for this insurance contract
   * @param productId ID string of the product linked to the insurance
   */
  function manualInsuranceResolution(
    bytes32 flightId,
    uint8 newStatusId,
    bytes32 productId)
  public
  onlyIfCreator {

    // go through the list of all insurances related to the given flight
    for (uint i = 0; i < insuranceList[flightId].length; i++) {

      // look for the insurance contract with the correct ID number
      if (areStringsEqual(insuranceList[flightId][i].productId, productId)) {

        // we check this contract is still ongoing before updating it
        if (insuranceList[flightId][i].status == 0) {

          // change the status of the insurance contract to the specified one
          insuranceList[flightId][i].status = newStatusId;

          // send an event about this update
          InsuranceUpdate(
            productId,
            flightId,
            insuranceList[flightId][i].premium,
            insuranceList[flightId][i].indemnity,
            newStatusId
          );

          return;
        }
      }
    }
  }

  function getInsurancesCount(bytes32 flightId) public view onlyIfCreator returns (uint) {
    return insuranceList[flightId].length;
  }

  function getInsurance(bytes32 flightId, uint index) public view onlyIfCreator returns (bytes32, uint, uint32, uint32, uint8) {
    Insurance memory ins = insuranceList[flightId][index];
    return (ins.productId, ins.limitArrivalTime, ins.premium, ins.indemnity, ins.status);
  }

}