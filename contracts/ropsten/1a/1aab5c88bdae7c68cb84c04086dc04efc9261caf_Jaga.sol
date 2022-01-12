/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

contract Jaga{

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    //to accept any incoming amount
    //function() public payable{}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //give out test ether to anyone who ask
    function withdraw(uint withdraw_amount) public{
        //limit withdraw amount
        require(withdraw_amount <= 0.1 ether);
        //send the amount to the address that asked for it
        msg.sender.transfer(withdraw_amount);
    }

    // Fallback function is called when msg.data is not empty
    //fallback() external payable {}


}