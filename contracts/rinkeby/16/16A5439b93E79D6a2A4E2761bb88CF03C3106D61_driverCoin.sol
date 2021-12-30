/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;
contract driverCoin {

  struct dataRecord {
    string driverId;
    uint distance;
    uint sharpBreaking;
    uint sharpAcc;
    uint overspeedLimit;
    uint rank;
    uint earnings;
    string earningDate;
  }
  
  mapping(string => dataRecord) private driverCoinBase;
  mapping(string => bool) driverExists;
  mapping(string => mapping(string => uint)) driverEarningsByDate;
  string[] private scbDriverId;

  event LogNewDriver (string driverId, uint rank, uint earnings, string earningDate);

  function createNewDriver(
    string memory driverId,
    uint distance,
    uint sharpBreaking,
    uint sharpAcc,
    uint overSpeedLimit,
    uint rank,
    uint earnings,
    string memory earningDate) external {

      //Check if the driver exists..
      require(driverExists[driverId]==false, "DATA RECORD: Driver Exists");
      driverCoinBase[driverId].driverId = driverId;
      driverCoinBase[driverId].distance = distance;
      driverCoinBase[driverId].sharpBreaking = sharpBreaking;
      driverCoinBase[driverId].sharpAcc = sharpAcc;
      driverCoinBase[driverId].overspeedLimit = overSpeedLimit;
      driverCoinBase[driverId].rank = rank;
      driverCoinBase[driverId].earnings = earnings;
      driverCoinBase[driverId].earningDate = earningDate;

      driverExists[driverId] = true;
      driverEarningsByDate[driverId][earningDate] = earnings;

      emit LogNewDriver(driverId,
          driverCoinBase[driverId].rank,
          driverCoinBase[driverId].earnings,
          driverCoinBase[driverId].earningDate);
  }

  function getDriverInfo(string memory driverId) view external returns(dataRecord memory) {
    return driverCoinBase[driverId];
  }

  function getDriverEarningsByDate(string memory driverId, string memory earningDate) view external returns(uint) {
    return driverEarningsByDate[driverId][earningDate];
  }

}