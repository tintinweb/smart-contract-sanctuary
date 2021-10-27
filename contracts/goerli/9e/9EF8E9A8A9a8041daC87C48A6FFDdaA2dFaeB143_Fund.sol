//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Fund {
    address private owner; // the address to which donations are sent to
    mapping(address => uint) private donations; // map of addresses and donation amounts
    uint private donators; // number of donators

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getDonators() public view returns (uint) {
        return donators;
    }

    function getDonations(address _donator) public view returns (uint) {
        return donations[_donator];
    }

    function donate() public payable {
        donations[msg.sender] += msg.value;
        donators++;
    }
}