/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract PayMe
{
    address payable public owner;
    uint256 public topAmount = 0;
    uint256 public totalDonations = 0;
    
    constructor () payable
    {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }
    
    function Withdraw() public payable onlyOwner
    {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to withdraw eth");
    }
    
    function PayUp() public payable
    {
        totalDonations += msg.value;

    }
}