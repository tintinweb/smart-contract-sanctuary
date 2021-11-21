// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract Boxzc {

    address public owner;
    uint public myUint;
    uint public myUint2;

    constructor() {
        require(owner == address(0), "Already initalized");
        owner = msg.sender;
    }
    function setvariables() public{
        myUint2=10;
    }

    function increment() public {
        require(msg.sender == owner, "Only the owner can increment"); //someone forget to uncomment this
        myUint++;
    }
    function addnewvalue() public {
        myUint2++;
    }
}