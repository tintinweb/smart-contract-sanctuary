/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract DonationBox {
    uint totalDonations = 0;  // total ETH donated through contract
    address payable admin;  // contract creator

    event DonationTransferred(address sender, uint amount);

    constructor() {
        admin = payable(msg.sender);
    }

    function donate() public payable {
        (bool sent, ) = admin.call{value: msg.value}("");
        require(sent, "Failed to send donation");
        totalDonations += msg.value;
        emit DonationTransferred(msg.sender, msg.value);
    }

    function getTotalDonations() view public returns (uint) {
        return totalDonations;
    }
}