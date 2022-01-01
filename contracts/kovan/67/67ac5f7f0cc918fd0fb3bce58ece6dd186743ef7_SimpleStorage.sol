/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage{

struct people{
    string firstName;
    string lastName;
    uint256 balance;
}

people[] public clients;

// mapping(string => unit256) public lastNameToBalance;

function addClient(string memory _firstName, string memory _lastName, uint256 _balance) public{
    clients.push(people(_firstName, _lastName, _balance));
}

function retrieve() public view returns(uint256){
    return 4;
}


}