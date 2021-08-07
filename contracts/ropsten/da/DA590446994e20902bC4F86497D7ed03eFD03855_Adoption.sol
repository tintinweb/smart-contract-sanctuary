// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract Adoption {
    address[16] public adopters;

    // Adopting a pet
    function adopt( uint petId) public returns (uint) {
        require( adopters[ petId] == address(0), "Pet is already adopted");
        require( 0 <= petId && petId <= 15, "... unkown pet");
        adopters[petId] = msg.sender;
        return petId;
    }

    // Reverting an adoption of a pet
    function abandon( uint petId) public returns (uint) {
        require( adopters[ petId] == msg.sender, "You are not the owner");
        require( 0 <= petId && petId <= 15, "... unkown pet");
        adopters[ petId] = address(0);
        return petId;
    }

    // Transfer pet
    function transferPet( uint petId, address target) public returns (uint) {
        require( adopters[ petId] == msg.sender, "You are not the owner");
        require( adopters[ petId] != target, "Target owns the pet already");
        require( 0 <= petId && petId <= 15, "... unkown pet");
        adopters[ petId] = target;
        return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }
}