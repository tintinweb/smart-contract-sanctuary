/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/* AB Contract

  set, get, increment, and decrement a number 
*/
contract Storage {
    uint256 public number = 10;
    uint256 public otherPublicNumber = 1337;
    uint256 private otherPrivateNumber = 5;
    uint[] public myArray = [11, 12, 13];
    uint[] public myArray2 = [number, otherPublicNumber, otherPrivateNumber];
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // For testing purposes, only owner can set a new number but anyone can increment / decrement
    function setNumber(uint256 num) onlyOwner public {
        number = num;
    }

    function increment() public {
        number++;
    }
    function incrementPublicNumber() public {
        otherPublicNumber++;
        myArray2 = [number, otherPublicNumber, otherPrivateNumber];
    }
    function incrementPrivateNumber() public {
        otherPrivateNumber++;
        myArray2 = [number, otherPublicNumber, otherPrivateNumber];
    }

    function decrement() public {
        number--;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
    function getPrivateNumber() public view returns (uint256) {
        return otherPrivateNumber;
    }
    
    
    function getArray() public view returns (uint[] memory) {
        return myArray;
    }
    function getArray2() public view returns (uint[] memory) {
        return myArray2;
    }
    function getElementArray2(uint i) public view returns (uint) {
        return myArray[i];
    }
    
    
}