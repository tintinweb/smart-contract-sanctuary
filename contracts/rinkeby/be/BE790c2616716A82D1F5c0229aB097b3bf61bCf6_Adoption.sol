// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Adoption {
  address[16] public adopters;

  // Adopting a pet
  function adopt(uint _petId) public returns (uint) {
    require(_petId >= 0 && _petId <= 15, "Invalid petId");
    require(adopters[_petId] == address(0), "Cannot adopt an already adopted pet");

    adopters[_petId] = msg.sender;

    return _petId;
  }

  // Retrieving the adopters
  function getAdopters() public view returns (address[16] memory) {
    return adopters;
  }

  // Remove adoption
  function removeAdoption(uint _petId) public returns (uint) {
    require(_petId >= 0 && _petId <= 15, "Invalid petId");
    require(adopters[_petId] == msg.sender, "Caller must be the adopter of pet");

    adopters[_petId] = address(0);

    return _petId;
  }
}

