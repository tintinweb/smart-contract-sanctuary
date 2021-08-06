/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// File: contracts/Adoption.sol

pragma solidity ^0.5.0;

contract Adoption {
    address[16] public adopters;

    // Adopting a pet
    function adopt(uint petId) public returns (uint) {
        require( adopters[petId] == address(0), "Pet is already adopted");
        require( 0 <= petId && petId <= 15);
        adopters[petId] = msg.sender;
        return petId;
    }

    // Reverting an adoption of a pet
    function abandon(uint petId) public returns (uint) {
        require( adopters[petId] == msg.sender, "You are not the owner");
        require( 0 <= petId && petId <= 15);
        adopters[petId] = address(0);
        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }
}

// File: contracts/Migrations.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}