/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DonationBox {
    uint totalDonations = 0;  // total ETH donated through contract
    address payable admin;  // contract creator

    constructor() {
        admin = payable(msg.sender);
    }

    function donate() public payable {
        totalDonations += msg.value;
        (bool sent, ) = admin.call{value: msg.value}("");
        require(sent, "Failed to send donation");
    }

    function getTotalDonations() view public returns (uint) {
        return totalDonations;
    }
}