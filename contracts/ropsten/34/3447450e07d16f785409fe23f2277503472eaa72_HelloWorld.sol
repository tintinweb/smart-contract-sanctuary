/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract HelloWorld {
    string value;

    function setValue(string memory _value) public{
        value = _value;
    }

    function getValue() public view returns (string memory){
        return value;
    }
}