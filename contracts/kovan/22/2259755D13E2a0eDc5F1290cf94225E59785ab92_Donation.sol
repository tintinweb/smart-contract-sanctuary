/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: Donation.sol

contract Donation {
    uint256 public donationSum;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function donate() public payable {
        donationSum += msg.value;
    }

    function withdraw() public payable {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
        donationSum = 0;
    }
}