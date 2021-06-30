//SPDX-License-Identifier: MIT
//Author: Jeff Prestes

pragma solidity 0.8.6;

contract RentalRecords {

    struct Rent {
        string locator;
        string renter;
        string addressHome;
        uint rentalValue;
    }

    address public owner;

    Rent[] public rentals;

    constructor() {
        owner = msg.sender;
    }

    function registerRental(
        string memory paramLocator,
        string memory paramRenter,
        string memory paramAddressHome,
        uint paramRentalValue
    ) external returns (bool) {
        require(msg.sender == owner, "Only the owner can register a rental contract");
        Rent memory newRentalRecord = Rent(paramLocator, paramRenter, paramAddressHome, paramRentalValue);
        rentals.push(newRentalRecord);
        return true;
    }
    
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}