/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;
contract test{
uint256 private aadharNumber;
string private firstName;
string private lastName;

constructor(uint256 _aadharNumber,string memory _firstName, string memory _lastName){
    aadharNumber = _aadharNumber;
    firstName = _firstName;
    lastName = _lastName;
}

function getAadharNumber()public view returns(uint256){
    return aadharNumber;
}

function getFirstName()public view returns(string memory){
    return firstName;
}

function getLastName()public view returns(string memory){
    return lastName;
}
}