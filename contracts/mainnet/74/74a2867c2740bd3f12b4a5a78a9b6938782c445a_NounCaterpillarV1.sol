/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Contract by: @backseats_eth


// This is an experimental implementation of an allow list game for NounCats (NounCats.com / @NounCats on Twitter).
// Periodically, this contract will open up and anyone can add themselves to the allow list before we mint on February 14, 2022.

// DISCLAIMER: This costs gas to add yourself to the allow list via this method. Yes, there are better and gasless ways to run an allow list (like a Google Form, lol). 
// This is not our only way of taking addresses before mint. It's just a fun one. 
contract NounCaterpillarV1 {
    
    // How many open slots are currently available in this contract
    uint8 public openSlots;
    
    // Using a bytes32 array rather than an array of addresses to save space and save the user on gas costs. These will eventually be used in a Merkle tree which the bytes32[] also lends itself to.
    bytes32[] public addresses;

    // A mapping to make sure you haven't been here before
    mapping(bytes32 => bool) private addressMapping;

    // A simplified implementation of Ownable 
    address private owner = 0x3a6372B2013f9876a84761187d933DEe0653E377;

    modifier onlyOwner { 
        require(msg.sender == owner, "Not owner");
        _;
    }

    // A function that only costs gas to add yourself to the allow list
    function addMeToAllowList() external {
        require(openSlots > 0, "Wait for spots to open up");
        bytes32 encoded = keccak256(abi.encodePacked(msg.sender));
        require(!addressMapping[encoded], "Already on list");
        addressMapping[encoded] = true;
        openSlots -= 1;
        addresses.push(encoded);
        delete encoded;
    }

    // A function that allows the owner to open up new spots
    function extendCaterpillar(uint8 _newSlots) external onlyOwner { 
        openSlots += _newSlots;
    }

}