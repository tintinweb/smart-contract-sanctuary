/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Mapping {
    
    mapping(uint => bool) public myMapping;
    mapping(address => bool) public myAddressMapping;
    mapping(uint => mapping(uint => bool)) nestedMapping;
    
    function setMapping(uint _index) public {
        myMapping[_index] = true;
    }
    
    function setAddressMapping() public {
        myAddressMapping[msg.sender] = true;
    }
    
    function setNestedMapping(uint x, uint y, bool value) public {
        nestedMapping[x][y] = value;
    } 
    
    function getNestedMapping(uint x, uint y) public view returns (bool) {
        return nestedMapping[x][y];
    } 
}