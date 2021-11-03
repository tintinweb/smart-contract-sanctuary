/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract GetSetSol{
    string savedString;
    uint savedValue;

    receive() external payable{}

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function setString(string memory newString) public{
        savedString = newString;
    }
    function getString() public view returns(string memory) {
        return savedString;
    }
    function setValue(uint newValue) public{
        savedValue = newValue;
    }
    function getValue() public view returns(uint){
        return (savedValue);
    }
}