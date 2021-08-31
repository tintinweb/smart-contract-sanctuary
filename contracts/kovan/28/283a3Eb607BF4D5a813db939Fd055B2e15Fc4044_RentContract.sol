/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentContract {

    struct rentInfo {
        bool isOccupied;
        address tenant;
        uint256 paymentDate;
        uint256 area;
        uint256 monthlyPrice;
    }

    address public owner;
    address public landlord;

    // contractsLength хранит длину rentContracts
    uint256 public contractsLength;
    rentInfo[] public rentContracts; 

    modifier onlyOwner {
        require(msg.sender == owner, "Only for owner");
        _;
    }

    constructor(address _landlord) {
        owner = msg.sender;
        landlord = _landlord;
    }

    function createRentContract (rentInfo memory _info) public onlyOwner {
        rentContracts.push(_info);
    }

    function deleteRentContract (uint256 _contractId) public onlyOwner {
        delete rentContracts[_contractId];
    }

    function signContract(uint256 _contractId) public {
        require(!rentContracts[_contractId].isOccupied, "This lot is already occupied");

        rentContracts[_contractId].tenant = msg.sender;
        rentContracts[_contractId].isOccupied = true;
    }

    function dummyFunction(uint256 zzz) public {

    }
}