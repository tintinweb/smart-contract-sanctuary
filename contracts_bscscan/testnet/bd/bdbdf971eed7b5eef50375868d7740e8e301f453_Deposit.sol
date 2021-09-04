/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Deposit {
    
    address private owner;
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    function deposit() payable public {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() public isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }
    
    receive() external payable {    }
}